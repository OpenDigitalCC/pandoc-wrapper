#!/bin/bash

# Copyright 2018 stuart@mackintosh.me
# License: BSD-3-Clause, see LICENSE file 
# https://opensource.org/licenses/BSD-3-Clause

# Do we have dependencies #TODO: Check...
P_BIN=`which pandoc`

# TODO: Check pandoc version and dependencies before continuing


if [ ! -x ${P_BIN} ]
 then
    echo "pandoc does not seem to be installed. or is not executable."
    echo "It is required to run this script, please check your installation"
    echo "Exiting..."
    exit 2
fi

# Some variables
SRCBASEDIR=../Source
OUTDIR=../Output
FSUFFIX=DRAFT
D_OUTFMT="pdf"
## Document title prefix:
D_TITLE_PRE="An Open Digital Approach for the NHS"

## Pandoc options
#P_VAR="--variable=links-as-notes"
P_EXTS="+definition_lists+example_lists+implicit_header_references+yaml_metadata_block+auto_identifiers+fenced_code_blocks+footnotes+link_attributes"
P_OPTS="--pdf-engine=xelatex --standalone --table-of-contents --number-sections "

# pdf-engine must be one of 
## wkhtmltopdf, weasyprint, prince, pdflatex, lualatex, xelatex, pdfroff, context

# Lets kick off with printing a blank line...
echo ""


# Function: Lets see what docs we could process
list_documents() {
D_AVAILABLE=()
for D_SRCDOCS in ${SRCBASEDIR}/*; do
    if [ -d ${D_SRCDOCS} ]
     then
        local D_DIR=`basename ${D_SRCDOCS}`
        D_AVAILABLE+=(${D_DIR})
    fi
done
}

# Function: what can we do?
display_usage () {
list_documents
	echo ""
	echo " Usage:"
	echo "  -a Compile all documents"
	echo "  -d <document> One of: ${D_AVAILABLE[@]}"
	echo "  -f pandoc format (odt,pdf,md,html,html5) pdf is default"
	echo ""
}

# Process user options
## Nothing entered
if [ $# == 0 ]
 then 
	echo "No options were passed"
	display_usage
	exit 1
fi

## We have parameters, which src doc do we want to process (and other questions)?

while getopts ":d:f:la" opt; do
  case $opt in

    a)
      list_documents
      echo -n "-a specified - producing all documents (${D_AVAILABLE[@]})" >&2
      DOCUMENTS=${D_AVAILABLE[@]}
      ;;

    d)
      echo -n "-d specified - producing $OPTARG " >&2
      DOCUMENTS=($OPTARG)
      ;;
    f)
    echo -n "Format: $OPTARG "
    D_OUTFMT=$OPTARG
    ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      display_usage
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      display_usage
      exit 1
      ;;
  esac
done


if [ -z "${DOCUMENTS[@]}" ]  
    then
	display_usage
	exit 1
fi

echo " Documents: ${DOCUMENTS[@]} "

# Customisations dependant on output format
case "${D_OUTFMT}" in
    pdf )
        #P_OPTS="${P_OPTS} --template=template-with-endnotes.latex"
        P_OPTS="${P_OPTS} --template=template-with-endnotes-revised.latex"
        ;;
    
   odt )
        ;;
esac

## Compile process called from the loop at the end of this file
compile() {

## File prefix passed by calling routine
F_PREFIX=$1

# Set the source dir for the fragments
SRCDIR=${SRCBASEDIR}/${F_PREFIX}

if [ ! -d ${SRCDIR} ]
 then
    echo ""
    echo "No such folder ${SRCDIR}, exiting..."
    echo ""
	exit 1
fi	

## Name for the temp metafile
F_TMPMETAFILE=/tmp/$$-${F_PREFIX}-meta.yaml

## Get last version
F_DOCVER=${SRCDIR}/DOC.VER
D_LAST_VER=$(cat $F_DOCVER)

## Check for content changes with md5 
C_SUMFILE=${SRCDIR}/content.md5
C_THISSUM=$(cat ${SRCDIR}/*.md |md5sum | cut -c -32 )
C_LASTSUM=$(cat ${C_SUMFILE} | cut -c -32 )

# Bump ver and set doc date if changed
if [ "${C_THISSUM}" != "${C_LASTSUM}" ]
 then
    D_THIS_VER="${D_LAST_VER%.*}.$((${D_LAST_VER##*.}+1))"
    D_THIS_VER_MAJOR=${D_THIS_VER%.*}    
    echo "Content changed since ${D_LAST_VER}, bumping to ${D_THIS_VER} (${C_THISSUM} != ${C_LASTSUM})"
    D_DATE=`date "+%e %B %Y"`
    ## Write new sum
    echo ${C_THISSUM} > ${C_SUMFILE}
 else
    D_THIS_VER=${D_LAST_VER}
    D_THIS_VER_MAJOR=${D_THIS_VER%.*}
    D_DATE=`date "+%e %B %Y" -r ${C_SUMFILE}`
fi 

# Make a single MD from the source fragments

F_MDPREPROCESS=${OUTDIR}/Preprocess-${F_PREFIX}.md

echo "Creating combined Markdown file ${F_MDPREPROCESS}"

> ${F_MDPREPROCESS}

for F_SRCMD in ${SRCDIR}/*.md
 do
    echo "Processing srcfile: ${F_SRCMD}"
    # Adding a newline to each file so that they don't disrupt formatting
    (cat ${F_SRCMD} ; echo "") >> ${F_MDPREPROCESS}
    RV=$?
    if [ "$RV" != "0" ]
     then
        echo ""
        echo "** Merge of ${F_SRCMD} to ${F_MDPREPROCESS} failed with RV: $RV, exiting"
        echo ""
        exit 1
    fi  

done

## Get some doc stats
D_lines=`wc ${F_MDPREPROCESS} | awk '{print $1}'`
D_words=`wc ${F_MDPREPROCESS} | awk '{print $2}'`

## Append stats to the MD
cat << EOAPPENDMD >> ${F_MDPREPROCESS}

\itshape

Document information

\small 

Version: ${F_PREFIX}-$D_THIS_VER ${FSUFFIX} (${D_OUTFMT})

Document date: ${D_DATE} (Compiled: `date "+%e %B %Y"`)

Word count: ${D_words} (${D_lines} lines)

\normalsize
\normalfont

Change log

- 30/11/2018 Cover page updated

EOAPPENDMD

# Set the document title
D_TITLE=`cat ${SRCDIR}/document-TITLE`

## Make the Pandoc variable YAML config file

cat << EOYAML > ${F_TMPMETAFILE}
---
documentclass: report
title: |
    ${D_TITLE_PRE}
subtitle: ${D_TITLE}
author: Stuart J Mackintosh
institute: OpenUK – The UK open source industry association
revisioninfo: Document revision ${D_THIS_VER} (${FSUFFIX} ${D_DATE})
titlepagefooterline: Digital copy available from https://openuk.uk/media-library/
logo: ../Source/OpenUK-Logo.png
toc-depth: 1
links-as-notes: false 
pagestyle: headings
fontfamily: sans
mainfont: DejaVuSans
sansfont: DejaVuSans
papersize: a4
fontsize: 12pt
twoside: yes
margin-left: 3cm
margin-right: 3cm
margin-top: 2cm
margin-bottom: 3cm
colorlinks: false
linkcolor: BlueViolet
header-includes: |
    \usepackage{fancyhdr}
    \usepackage{lastpage}
    \pagestyle{fancy}
    \fancyhf{}
    \fancyhead[LE,RO]{\textsl{\leftmark}}
    \fancyfoot[CO,CE]{${D_TITLE_PRE}}
    \fancyfoot[LE,RO]{\thepage\ of \pageref{LastPage}}
    \renewcommand{\headrule}{\hbox to\headwidth{%
        \color{boxblue}\leaders\hrule height \headrulewidth\hfill}}
    \renewcommand{\footrule}{\hbox to\headwidth{%
        \color{boxblue}\leaders\hrule height \headrulewidth\hfill}}
    \renewcommand{\headrulewidth}{0.4pt}
    \renewcommand{\footrulewidth}{0.4pt}
    \renewcommand{\chaptermark}[1]{%
        \markboth{\thechapter.\ #1}{}}
...
EOYAML
# Colours: https://en.wikibooks.org/wiki/LaTeX/Colors
# fancyhdr https://texblog.org/2007/11/07/headerfooter-in-latex-with-fancyhdr/

## Set up the source and destination files
F_PSRC=${F_MDPREPROCESS}
F_POUTBASE="`echo "${D_TITLE_PRE}-${D_TITLE}" |sed "s/[^[:alpha:].-]/-/g"`-${D_THIS_VER_MAJOR}-${FSUFFIX}.${D_OUTFMT}"
F_POUT="${OUTDIR}/${F_POUTBASE}"

## Build out the pandoc command

COMMAND=$(cat <<EOC
${P_BIN}  \
--citeproc \
${P_VAR} \
${P_OPTS} \
--from markdown${P_EXTS} \
${F_PSRC} \
${F_TMPMETAFILE} \
-o ${F_POUT} 
EOC
)

# --to ${D_OUTFMT} \

## Ok, lets get on with this thing and see what happens...

# Tell the user what we are just about to do
echo ""
echo "Compiling source: ${F_PSRC}"
echo "To destination: ${F_POUT}"

# This is where we run pandoc (although that may not be so obvious...)
# We do it this ay so it is quiet if it works but the error is available if we need it
DEBUG=`${COMMAND} 2>&1`
RV=$?

# Check the return, print if it broke
if [ "$RV" != "0" ]
 then
    echo ""
    echo "** Compile of document ${D_THIS_VER} failed"
    echo ""
    echo "The command was:"
    echo "${COMMAND}"
    echo ""
    echo "${DEBUG}"
    echo ""
    echo "Pandoc version information:"    
    ${P_BIN} -v
    echo ""
    echo "Exiting..."
    echo ""
    echo "YAML meta file is saved here: ${F_TMPMETAFILE}"
    echo ""
    exit 1    

 else
	## Tidy up
	rm ${F_TMPMETAFILE}
	# Lets tell the user what just happened
	echo ""
	echo "Compiled document ${D_THIS_VER} in ${D_OUTFMT} format"
	echo ""
	## We are done.
fi

} # End of compile


# the main loop that calls the compile
for D in ${DOCUMENTS[@]}
 do
    ## Do the thing
    echo "Compiling $D"
    compile $D

    ## Bump version file
    echo "${D_THIS_VER}" > ${F_DOCVER}
	exit 0
done

