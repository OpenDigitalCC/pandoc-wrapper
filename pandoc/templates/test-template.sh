#!/bin/bash

# Test script for reorganized Eisvogel template
# This script compiles the test document and provides feedback

set -e  # Exit on error

TEMPLATE="eisvogel-reorganized.latex"
INPUT="test-document.md"
OUTPUT="test-output.pdf"

echo "=========================================="
echo "Eisvogel Template Test Script"
echo "=========================================="
echo

# Check if required files exist
if [ ! -f "$TEMPLATE" ]; then
    echo "ERROR: Template file '$TEMPLATE' not found!"
    exit 1
fi

if [ ! -f "$INPUT" ]; then
    echo "ERROR: Input file '$INPUT' not found!"
    exit 1
fi

# Check if pandoc is installed
if ! command -v pandoc &> /dev/null; then
    echo "ERROR: pandoc is not installed!"
    echo "Please install pandoc to continue."
    exit 1
fi

# Check if xelatex is installed (preferred for Unicode)
if ! command -v xelatex &> /dev/null; then
    echo "WARNING: xelatex not found. Checking for pdflatex..."
    if ! command -v pdflatex &> /dev/null; then
        echo "ERROR: No LaTeX engine found (xelatex or pdflatex)!"
        echo "Please install texlive or similar."
        exit 1
    fi
    LATEX_ENGINE="pdflatex"
    echo "Note: Using pdflatex. For full Unicode support, install xelatex."
else
    LATEX_ENGINE="xelatex"
fi

echo "Configuration:"
echo "  Template: $TEMPLATE"
echo "  Input:    $INPUT"
echo "  Output:   $OUTPUT"
echo "  Engine:   $LATEX_ENGINE"
echo

# Compile the document
echo "Compiling document..."
echo "--------------------------------------"

# Run pandoc and capture output
pandoc "$INPUT" \
    -o "$OUTPUT" \
    --template="$TEMPLATE" \
    --pdf-engine="$LATEX_ENGINE" \
    --listings \
    --number-sections \
    2>&1 | tee compile.log

# Check if compilation succeeded by verifying output file exists
if [ -f "$OUTPUT" ]; then
    echo "--------------------------------------"
    echo
    echo "✓ SUCCESS: Document compiled successfully!"
    echo "  Output file: $OUTPUT"
    echo
    
    # Check file size
    SIZE=$(du -h "$OUTPUT" | cut -f1)
    echo "  File size: $SIZE"
    
    # Check page count if pdfinfo is available
    if command -v pdfinfo &> /dev/null; then
        PAGES=$(pdfinfo "$OUTPUT" 2>/dev/null | grep "Pages:" | awk '{print $2}')
        if [ -n "$PAGES" ]; then
            echo "  Pages: $PAGES"
        fi
    fi
    
    echo
    echo "Review the PDF to verify:"
    echo "  • Title page formatting"
    echo "  • Table of contents"
    echo "  • Code syntax highlighting"
    echo "  • Table formatting"
    echo "  • Headers and footers"
    echo "  • Color scheme (ODCC colors)"
    echo
    
else
    echo "--------------------------------------"
    echo
    echo "✗ ERROR: Compilation failed!"
    echo "  No output file was created."
    echo
    echo "Check compile.log for details."
    echo
    
    # Show last 20 lines of error
    if [ -f compile.log ]; then
        echo "Last errors from compile.log:"
        echo "--------------------------------------"
        tail -20 compile.log
        echo "--------------------------------------"
    fi
    
    echo
    echo "Common issues:"
    echo "  • Missing LaTeX packages"
    echo "  • Unicode characters with pdflatex (try xelatex)"
    echo "  • Template syntax errors"
    echo "  • Incompatible pandoc version"
    echo
    echo "Suggested fix:"
    echo "  Try running with XeLaTeX instead:"
    echo "  pandoc $INPUT -o $OUTPUT --template=$TEMPLATE --pdf-engine=xelatex"
    echo
    exit 1
fi

echo "=========================================="
echo "Test Complete"
echo "=========================================="
