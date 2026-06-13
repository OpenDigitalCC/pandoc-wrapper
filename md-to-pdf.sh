#!/bin/bash

# Script version marker
SCRIPT_VERSION="2024-12-12-v7-alpha-sort"

# Global variables
MDSRC=()
WD=""
export LC_ALL=C
DEBUG=0
ORDER_ALPHA=0
NO_VIEWER=0

# Configuration
INCDIR=~/.pandoc/templates
BRANDDIR=~/.pandoc/brands
PDF_VIEWER=/usr/bin/evince
P_ENGINE=xelatex

# Initialize variables
TMPDIR=""
FNMAX=0
MDCONTENT=""
DOC_DATE=""
BRAND_LUA=""

# Utility functions
debug_log() {
    if [[ $DEBUG -eq 1 ]]; then
        echo "DEBUG: $1" >&2
    fi
}

log_message() {
    echo -ne "\r - $1" >&2
}

error_exit() {
    echo "$1" >&2
    exit "$2"
}

is_wanted() {
    case "$1" in
        *.md|*.yaml) return 0 ;;
        *)           return 1 ;;
    esac
}

check_mermaid_filter() {
    if command -v mermaid-filter >/dev/null 2>&1; then
        true # disable mermaid
        #  echo "mermaid-filter"
    fi
}

load_filters() {
    local filter
    filter=$(check_mermaid_filter)
    if [ -n "$filter" ]; then
        echo "-F $filter"
    fi
}

# X session detection
is_x_session() {
    [[ -n "$DISPLAY" ]]
}

# Show error in X modal dialog
show_x_error() {
    local title="$1"
    local message="$2"
    local logfile="$3"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    if ! is_x_session; then
        return 1
    fi
    
    # Build header with context information
    local header="Time: $timestamp\n"
    header+="Source files: ${MDSRC[*]}\n"
    [[ -n "$DOC_TITLE" ]] && header+="Document: $DOC_TITLE\n"
    [[ -n "$DOC_BRAND" ]] && header+="Brand: $DOC_BRAND\n"
    header+="Working directory: $WD\n"
    header+="\n"
    
    # Read log content if file exists
    local log_content=""
    if [[ -n "$logfile" && -f "$logfile" ]]; then
        log_content=$(cat "$logfile" 2>/dev/null)
    fi
    
    # Try zenity first (most feature-rich, supports text display)
    if command -v zenity >/dev/null 2>&1; then
        if [[ -n "$log_content" ]]; then
            # Use text-info dialog to show log content with header
            {
                echo -e "$header"
                echo "=== Error Message ==="
                echo "$message"
                echo ""
                echo "=== Log Output ==="
                echo "$log_content"
            } | zenity --text-info \
                --title="$title" \
                --width=900 \
                --height=700 \
                --font="monospace 10" 2>/dev/null
        else
            zenity --error \
                --title="$title" \
                --text="${header}${message}" \
                --width=600 2>/dev/null
        fi
        return 0
    fi
    
    # Try gmessage (simple but reliable)
    if command -v gmessage >/dev/null 2>&1; then
        local full_msg="${header}${message}"
        if [[ -n "$log_content" ]]; then
            full_msg="${full_msg}\n\n--- Log Output ---\n${log_content}"
        fi
        echo -e "$full_msg" | gmessage -title "$title - $timestamp" -file - 2>/dev/null
        return 0
    fi
    
    # Fallback to xmessage (always available in X)
    if command -v xmessage >/dev/null 2>&1; then
        local full_msg="${header}${message}"
        if [[ -n "$log_content" ]]; then
            full_msg="${full_msg}\n\n--- Log Output ---\n${log_content}"
        fi
        echo -e "$full_msg" | xmessage -center -title "$title - $timestamp" -file - 2>/dev/null
        return 0
    fi
    
    return 1
}

# URL handling functions
is_url() {
    local url="$1"
    local regex='^(https:|http:|www\.)\S*'
    [[ "$url" =~ $regex ]]
}

download_url() {
    local url="$1"
    debug_log "download_url START with URL: $url"
    
    local tmpfile
    tmpfile=$(mktemp /tmp/md-to-pdf-XXXXXX.md)
    debug_log "mktemp created: $tmpfile"
    
    wget "$url" -O "$tmpfile" -q || error_exit "Download of $url failed, exiting..." 1
    debug_log "wget completed successfully"
    
    [[ -f "$tmpfile" ]] || error_exit "File $tmpfile does not exist, download error? Exiting..." 1
    debug_log "File exists check passed"
    
    # Remove TOC markers
    sed -i 's/\[TOC\]//' "$tmpfile"
    debug_log "TOC markers removed"
    
    log_message "Downloaded $url to $tmpfile"
    debug_log "download_url RETURNING: $tmpfile"
    echo "$tmpfile"
}

# File collection functions
add_path() {
    local p="$1"
    
    debug_log "add_path called with: $p"
    
    # Check if it's a URL - download and add to sources
    if is_url "$p"; then
        debug_log "Detected as URL, calling download_url"
        local downloaded_file
        downloaded_file=$(download_url "$p")
        debug_log "download_url returned: $downloaded_file"
        MDSRC+=("$downloaded_file")
        debug_log "Added to MDSRC array"
    elif [[ -d "$p" ]]; then
        # Recursively gather *.md and *.yaml from this directory
        mapfile -d '' -t files < <(find "$p" -type f \( -name '*.md' -o -name '*.yaml' \) -print0 | sort -z)
        MDSRC+=("${files[@]}")
    elif [[ -f "$p" ]] && is_wanted "$p"; then
        MDSRC+=("$p")
    fi
}

collect_source_files() {
    for arg in "$@"; do
        # Skip option flags
        if [[ "$arg" == "--order-alpha" || "$arg" == "--debug" || "$arg" == "--no-viewer" ]]; then
            continue
        fi
        add_path "$arg"
    done
    
    # Sort files alphabetically if requested
    if [[ $ORDER_ALPHA -eq 1 ]]; then
        debug_log "Sorting ${#MDSRC[@]} files alphabetically"
        # Use readarray to sort the MDSRC array
        IFS=$'\n' MDSRC=($(sort <<<"${MDSRC[*]}"))
        unset IFS
        debug_log "Files after sorting: ${MDSRC[*]}"
    fi
}

# Parse command-line options
parse_options() {
    for arg in "$@"; do
        case "$arg" in
            --order-alpha)
                ORDER_ALPHA=1
                debug_log "Alphabetical ordering enabled"
                ;;
            --debug)
                DEBUG=1
                debug_log "Debug mode enabled"
                ;;
            --no-viewer)
                NO_VIEWER=1
                debug_log "PDF viewer suppressed"
                ;;
        esac
    done
}

# Validation functions
validate_arguments() {
    if [[ -z "$MDSRC" ]]; then
        echo ""
        echo "Usage: $0 [OPTIONS] <markdown source files / URL> [working directory (optional)]"
        echo ""
        echo "Options:"
        echo "  --order-alpha    Sort input files alphabetically (dictionary order)"
        echo "  --debug          Enable debug output"
        echo "  --no-viewer      Suppress automatic PDF viewer launch"
        echo ""
        echo "No source markdown specified, exiting...."
        echo ""
        exit 1
    fi
}

validate_working_directory() {
    if [[ ! -w "$WD" ]]; then
        error_exit "Working directory $WD does not exist or is not writable, exiting..." 2
    fi
}

# Content processing functions
process_source_files() {
    debug_log "process_source_files START"
    debug_log "MDSRC array has ${#MDSRC[@]} elements"
    
    for ifile in "${MDSRC[@]}"; do
        debug_log "Processing file: '$ifile'"
        log_message "Reading $ifile"
        
        [[ -f "$ifile" ]] || error_exit "File $ifile does not exist, Exiting..." 1
        
        # Append content
        MDCONTENT="${MDCONTENT}"$'\n'"$(cat "$ifile")"$'\n\n'
        echo -ne " (length: ${#MDCONTENT})"
    done
    debug_log "process_source_files COMPLETE"
}

# Brand configuration functions
load_brand_config() {
    local brand="$1"
    local brand_file="${BRANDDIR}/brand-${brand}.yaml"
    
    if [[ ! -f "$brand_file" ]]; then
        echo "Warning: Brand file not found: $brand_file" >&2
        return 1
    fi
    
    debug_log "Loading brand config: $brand_file"
    
    # Read brand content
    local brand_content
    brand_content=$(cat "$brand_file")
    
    # Prepend brand config before document content
    # This way document settings override brand defaults
    MDCONTENT="${brand_content}"$'\n\n'"${MDCONTENT}"
    
    log_message "Loaded brand config: $brand"
    
    # Check for brand-specific Lua filter
    local brand_lua="${BRANDDIR}/brand-${brand}.lua"
    if [[ -f "$brand_lua" ]]; then
        debug_log "Found brand Lua filter: $brand_lua"
        BRAND_LUA="$brand_lua"
        log_message "Loaded brand Lua filter: $brand"
    fi
    
    return 0
}

extract_metadata() {
    # Extract only the YAML frontmatter (between first --- and second ---)
    # This avoids parsing YAML examples in code blocks
    local yaml_frontmatter
    yaml_frontmatter=$(echo "$MDCONTENT" | awk '/^---$/{if(++count==1) next; if(count==2) exit} count==1')
    
    debug_log "YAML frontmatter extracted:"
    debug_log "$yaml_frontmatter"
    
    # Extract brand first (needed to load brand config)
    DOC_BRAND=$(echo "$yaml_frontmatter" | awk -F ': ' '$1=="brand" {$1=""; print substr($0,2)}' | xargs)
    debug_log "DOC_BRAND: '$DOC_BRAND'"
    
    # Extract title and clean it up - handle colons in quoted values
    DOC_TITLE=$(echo "$yaml_frontmatter" | awk -F ': ' '$1=="title" {$1=""; print substr($0,2)}' | tr -d '"' | tr -d "'" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    debug_log "DOC_TITLE: '$DOC_TITLE'"
    
    # Extract subtitle and clean it up
    DOC_SUBTITLE=$(echo "$yaml_frontmatter" | awk -F ': ' '$1=="subtitle" {$1=""; print substr($0,2)}' | tr -d '"' | tr -d "'" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    debug_log "DOC_SUBTITLE: '$DOC_SUBTITLE'"
    
    # Extract template (check both "template:" and "pandoc-template:")
    DOC_P_TEMPLATE=$(echo "$yaml_frontmatter" | awk -F ': ' '$1=="pandoc-template" || $1=="template" {$1=""; print substr($0,2); exit}' | tr -d '"' | tr -d "'" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    debug_log "DOC_P_TEMPLATE: '$DOC_P_TEMPLATE'"
    
    # Extract other metadata and strip quotes
    DOC_P_ENGINE=$(echo "$yaml_frontmatter" | awk -F ': ' '$1=="pdf-engine" {$1=""; print substr($0,2)}' | tr -d '"' | tr -d "'" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    DOC_P_TLD=$(echo "$yaml_frontmatter" | awk -F ': ' '$1=="top-level-division" {$1=""; print substr($0,2)}' | tr -d '"' | tr -d "'" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    DOC_TYPE=$(echo "$yaml_frontmatter" | awk -F ': ' '$1=="type" {$1=""; print substr($0,2)}' | tr -d '"' | tr -d "'" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    DOC_PRINTREADY=$(echo "$yaml_frontmatter" | awk -F ': ' '$1=="printready" {$1=""; print substr($0,2)}' | xargs)
    DOC_DATE=$(echo "$yaml_frontmatter" | awk -F ': ' '$1=="date" {$1=""; print substr($0,2)}' | tr -d '"' | tr -d "'" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
}

generate_filename() {
    local fname
    
    # If we have title metadata, use it
    if [[ -n "$DOC_TITLE" || -n "$DOC_SUBTITLE" || -n "$DOC_TYPE" ]]; then
        fname="$(echo "${DOC_TYPE}${DOC_TITLE##*( )}_${DOC_SUBTITLE##*( )}" | sed -e 's/["]//' | sed -e 's/[^A-Za-z0-9._-]/_/g')"
        
        # Remove trailing underscores and dashes
        fname="${fname%_}"
        fname="${fname%-}"
    else
        # No metadata - use source filename or timestamp
        if [[ ${#MDSRC[@]} -eq 1 && -f "${MDSRC[0]}" ]]; then
            # Single file input - use its basename
            fname="$(basename "${MDSRC[0]}" .md)"
            fname="$(basename "$fname" .yaml)"
        else
            # Multiple files, URL, or no identifiable source - use timestamp
            fname="md-to-pdf-$(date +%Y%m%d-%H%M%S)"
        fi
    fi
    
    # Hard limit to 80 characters for safety (leaves room for temp paths and suffixes)
    if [[ ${#fname} -gt 80 ]]; then
        fname="${fname:0:80}"
        # Clean up in case we cut in the middle of underscores/dashes
        fname="${fname%_}"
        fname="${fname%-}"
    fi
    
    debug_log "Generated filename: $fname (length: ${#fname})"
    echo "$fname"
}

setup_pandoc_options() {
    # Set template if specified
    if [[ -n $DOC_P_TEMPLATE ]]; then
        P_TEMPLATE=" --template=$INCDIR/$(echo "$DOC_P_TEMPLATE" | xargs).latex "
    fi
    
    # Set engine if specified
    if [[ -n $DOC_P_ENGINE ]]; then
        P_ENGINE=$(echo "$DOC_P_ENGINE" | xargs)
    fi
    
    # Set top-level division if specified
    if [[ -n $DOC_P_TLD ]]; then
        P_TLD="--top-level-division=$(echo "$DOC_P_TLD" | xargs)"
    fi
    
    # Set type if specified
    if [[ -n $DOC_TYPE ]]; then
        echo " - Type: $DOC_TYPE"
        P_TYPE=" -t $DOC_TYPE "
    fi
    
    # Show print-ready status
    if [[ "$DOC_PRINTREADY" == "true" ]]; then
        echo " - Print-ready mode: crop marks will be added"
    fi
}

ensure_yaml_frontmatter() {
    local testyaml
    testyaml=$(echo "$MDCONTENT" | head | grep -qE '^[[:space:]]*([a-zA-Z0-9_-]+:|---{3,10})'; echo $?)
    
    if [[ $testyaml -ne 0 ]]; then
        echo "No YAML data in compiled document, making some"
        local yaml
        yaml="$(cat <<EOY
---
book: true
documentclass: scrartcl
---
EOY
        )"
        
        MDCONTENT=$(cat <<EOC
${yaml}

${MDCONTENT}
EOC
        )
    fi
}

create_content_file() {
    local fname="$1"
    local contentfile="${TMPDIR}/${fname}-compiled.md"
    
    debug_log "Creating content file: $contentfile"
    
    # Write content to file
    printf '%s\n' "$MDCONTENT" > "$contentfile"
    
    if [[ ! -f "$contentfile" ]]; then
        error_exit "Failed to create content file: $contentfile" 1
    fi
    
    debug_log "Content file created: $(wc -l < "$contentfile") lines"
    
    echo "$contentfile"
}

run_pandoc() {
    local contentfile="$1"
    local dstfile="$2"
    local outfile="${TMPDIR}/pandoc-stdout.txt"
    
    echo "Producing $dstfile in $WD on $DOC_DATE"
    
    # Setup debug options
    local pandoc_debug=""
    if [[ $DEBUG -eq 1 ]]; then
        pandoc_debug=" +RTS -s -RTS --log=/tmp/pandoc.log.json "
    fi
    
    # Setup Lua filters
    local lua_filters=" --lua-filter=\"$INCDIR/document-filters.lua\" "
    if [[ -n "$BRAND_LUA" ]]; then
        lua_filters="$lua_filters --lua-filter=\"$BRAND_LUA\""
        debug_log "Including brand Lua filter: $BRAND_LUA"
    fi
    
    # Build the complete pandoc command
    local pandoc_cmd="pandoc $pandoc_debug $(load_filters) $lua_filters --pdf-engine=\"$P_ENGINE\" ${P_TEMPLATE} $P_TLD --metadata=date:\"$DOC_DATE\" -f markdown+inline_notes \"$contentfile\" -t pdf -o \"$dstfile\""
    
    # Run pandoc
    if pandoc $pandoc_debug \
        $(eval echo "$lua_filters") \
        --pdf-engine="$P_ENGINE" \
        ${P_TEMPLATE} \
        $P_TLD \
        --metadata=date:"$DOC_DATE" \
        -f markdown+inline_notes \
        "$contentfile" \
        -t pdf \
        $(load_filters) \
        -o "$dstfile" > "$outfile" 2>&1; then
        
        echo "✅ pandoc succeeded"
        
        # Open PDF viewer unless suppressed
        if [[ $NO_VIEWER -eq 0 ]]; then
            echo "Opening $dstfile with $PDF_VIEWER"
            $PDF_VIEWER "$dstfile" &
        else
            echo "PDF created: $dstfile (viewer suppressed)"
        fi
    else
        local exit_code=$?
        if [[ $exit_code -eq 130 ]]; then
            echo "❌ pandoc interrupted (Ctrl-C pressed)"
        else
            echo "❌ pandoc failed (exit code $exit_code)"
        fi
        echo "Command used: $pandoc_cmd"
        echo "See $outfile"
        
        # Show X dialog if in X session
        show_x_error "Pandoc Conversion Failed" \
            "PDF generation failed with exit code $exit_code.\n\nCheck the log file for details." \
            "$outfile"
        
        exit $exit_code
    fi
}

initialize_environment() {
    DOC_PROCESS_DATE=$(date "+%A %d %B %Y")
    TMPDIR=$(mktemp -d)
    WD="${WD:-"$(pwd)"}"
    FNMAX=$(( $(getconf NAME_MAX "$WD") - 20 ))
}

cleanup() {
    # Cleanup function could be added here if needed
    # For now, we keep temp files for debugging
    :
}

# Main function
main() {
    debug_log "Running script version: $SCRIPT_VERSION"
    
    # Parse options first
    parse_options "$@"
    
    initialize_environment
    collect_source_files "$@"
    validate_arguments
    validate_working_directory
    
    process_source_files
    extract_metadata
    
    # Load brand configuration if specified
    if [[ -n "$DOC_BRAND" ]]; then
        # Save document metadata before loading brand
        local saved_title="$DOC_TITLE"
        local saved_subtitle="$DOC_SUBTITLE"
        local saved_type="$DOC_TYPE"
        local saved_date="$DOC_DATE"
        local saved_printready="$DOC_PRINTREADY"
        
        load_brand_config "$DOC_BRAND"
        
        # Re-extract metadata to get brand defaults
        extract_metadata
        
        # Restore document metadata (document values override brand defaults)
        [[ -n "$saved_title" ]] && DOC_TITLE="$saved_title"
        [[ -n "$saved_subtitle" ]] && DOC_SUBTITLE="$saved_subtitle"
        [[ -n "$saved_type" ]] && DOC_TYPE="$saved_type"
        [[ -n "$saved_date" ]] && DOC_DATE="$saved_date"
        [[ -n "$saved_printready" ]] && DOC_PRINTREADY="$saved_printready"
        
        debug_log "After brand merge - DOC_TITLE: '$DOC_TITLE'"
        debug_log "After brand merge - DOC_SUBTITLE: '$DOC_SUBTITLE'"
    fi
    
    DOC_DATE=${DOC_DATE:-$DOC_PROCESS_DATE}

    local fname
    fname=$(generate_filename)
    
    setup_pandoc_options
    ensure_yaml_frontmatter
    
    echo " - Total content length: ${#MDCONTENT} Filters: $(load_filters)"
    
    local contentfile
    contentfile=$(create_content_file "$fname")
    
    local dstfile="${WD}/${fname}.pdf"
    run_pandoc "$contentfile" "$dstfile"
    
    cleanup
}

# Run main function with all arguments
main "$@"
