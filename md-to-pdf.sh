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

# Resolve the directory this script lives in, so bundled helpers and assets can
# be found whether the script is run from the repo, ~/.local/bin, or /usr/bin.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Locate the templates/brands asset tree. Order of preference:
#   1. explicit environment overrides (set by an installer or the user)
#   2. an asset tree shipped next to this script (system / prefix install)
#   3. the per-user default under ~/.pandoc
locate_assets() {
    local base
    for base in \
        "$SCRIPT_DIR/../share/pandoc-wrapper" \
        "$SCRIPT_DIR/pandoc" \
        "/usr/share/pandoc-wrapper" \
        "/usr/local/share/pandoc-wrapper"; do
        if [[ -d "$base/templates" ]]; then
            echo "$base"
            return 0
        fi
    done
    return 1
}

# Read a `key = value` setting from the config file without sourcing it.
# Config path: $MD_TO_PDF_CONFIG, else XDG (~/.config/pandoc-wrapper/config).
CONFIG_FILE="${MD_TO_PDF_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/pandoc-wrapper/config}"
read_config_value() {
    local key="$1" v
    [[ -f "$CONFIG_FILE" ]] || return 1
    v=$(grep -E "^[[:space:]]*${key}[[:space:]]*=" "$CONFIG_FILE" | tail -1 \
        | sed -E "s/^[[:space:]]*${key}[[:space:]]*=[[:space:]]*//; s/[[:space:]]*\$//")
    [[ -n "$v" ]] || return 1
    # Expand a leading ~ to $HOME.
    [[ "$v" == "~"* ]] && v="${HOME}${v#\~}"
    echo "$v"
}

# Configuration. Templates ship with the tool; brands are user data and live in a
# separate, configurable base folder (outside this repo), so brands can be
# managed in their own repos/packages.
_ASSET_BASE="$(locate_assets || true)"
INCDIR="${MD_TO_PDF_TEMPLATES:-${_ASSET_BASE:+$_ASSET_BASE/templates}}"
INCDIR="${INCDIR:-$HOME/.pandoc/templates}"

# Brands base resolution:
#   1. MD_TO_PDF_BRANDS environment override (authoritative)
#   2. brands_dir from the config file (authoritative)
#   3. otherwise the first existing of: a co-located brands tree, the XDG data
#      default, the legacy ~/.pandoc/brands - defaulting to the XDG path.
# BRANDS_CONFIGURED records whether the user pointed us at a brands base (env or
# config). When not, we fall back to the bundled default and hint how to set one.
BRANDS_CONFIGURED=1
BRANDDIR="${MD_TO_PDF_BRANDS:-$(read_config_value brands_dir || true)}"
if [[ -z "$BRANDDIR" ]]; then
    BRANDS_CONFIGURED=0
    _xdg_brands="${XDG_DATA_HOME:-$HOME/.local/share}/pandoc-wrapper/brands"
    for _c in "${_ASSET_BASE:+$_ASSET_BASE/brands}" "$_xdg_brands" "$HOME/.pandoc/brands"; do
        [[ -n "$_c" && -d "$_c" ]] && { BRANDDIR="$_c"; break; }
    done
    BRANDDIR="${BRANDDIR:-$_xdg_brands}"
fi

# The bundled default brand (plain) ships with the tool. It is the fallback when
# a brand is not in the user's external brands base, so `plain` stays available
# no matter where brands_dir points.
BUNDLED_BRANDDIR="${_ASSET_BASE:+$_ASSET_BASE/brands}"

PDF_VIEWER="${MD_TO_PDF_VIEWER:-/usr/bin/evince}"
P_ENGINE=xelatex

# Per-brand asset directory (logos, cover PDFs); set when a brand loads.
BRAND_ASSET_DIR=""

# Declarative front-matter registry: YAML key -> shell variable it populates.
# To react to a new front-matter field, add one line here - nothing else in the
# parsing path needs to change. Multiple YAML keys may target the same variable
# (e.g. template / pandoc-template).
declare -A META_FIELDS=(
    [brand]=DOC_BRAND
    [title]=DOC_TITLE
    [subtitle]=DOC_SUBTITLE
    [template]=DOC_P_TEMPLATE
    [pandoc-template]=DOC_P_TEMPLATE
    [pdf-engine]=DOC_P_ENGINE
    [top-level-division]=DOC_P_TLD
    [type]=DOC_TYPE
    [printready]=DOC_PRINTREADY
    [date]=DOC_DATE
)

# Locate a bundled helper across the layouts the script may be installed in.
find_helper() {
    local name="$1" c
    for c in \
        "$SCRIPT_DIR/scripts/$name" \
        "$SCRIPT_DIR/$name" \
        "$SCRIPT_DIR/../lib/md-to-pdf/$name" \
        "$SCRIPT_DIR/../share/md-to-pdf/$name" \
        "/usr/lib/md-to-pdf/$name"; do
        if [[ -f "$c" ]]; then
            echo "$c"
            return 0
        fi
    done
    return 1
}

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

print_help() {
    cat <<EOF
Usage: md-to-pdf [OPTIONS] <markdown file(s) / directory / URL>

Convert Markdown with YAML front matter to a branded PDF via Pandoc and XeLaTeX.

Options:
  --order-alpha   Sort multiple input files alphabetically
  --debug         Verbose debug output
  --no-viewer     Do not open the PDF viewer after building
  -h, --help      Show this help and exit

Brands:
  Choose a brand in a document's front matter:  brand: <name>
  'plain' is the bundled default. Your own brands live in an external base
  folder - one subfolder per brand: <base>/<name>/template.yaml plus its assets
  (logo.png, cover.pdf, ...), referenced by bare filename.

  The brands base is resolved in order:
    1. \$MD_TO_PDF_BRANDS environment variable
    2. brands_dir in the config file
    3. the bundled default brand (plain)

Configuration:
  Config file: ${CONFIG_FILE}
  Point it at your brands base, e.g.:
    brands_dir = \$HOME/pandoc-brands

Resolved paths now:
  templates : ${INCDIR}
  brands    : ${BRANDDIR}$([[ $BRANDS_CONFIGURED -eq 0 ]] && echo "  (bundled default - no brands_dir configured)")

See 'man md-to-pdf' for full documentation.
EOF
}

# A one-line nudge for users who have not configured their own brands base.
print_brands_hint() {
    [[ $BRANDS_CONFIGURED -eq 0 ]] || return 0
    echo "md-to-pdf: no brands_dir configured; using bundled 'plain'. Run 'md-to-pdf --help' to set up your own brands." >&2
}

# Parse command-line options
parse_options() {
    for arg in "$@"; do
        case "$arg" in
            -h|--help)
                print_help
                exit 0
                ;;
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

    # Resolve a brand by name, in order:
    #   1. external base, folder layout:  <BRANDDIR>/<brand>/template.yaml
    #   2. bundled defaults, folder layout: <BUNDLED>/<brand>/template.yaml
    #   3. legacy flat file:               <BRANDDIR>/brand-<brand>.yaml
    local brand_dir="" brand_file=""
    local cand
    for cand in \
        "${BRANDDIR}/${brand}" \
        "${BUNDLED_BRANDDIR:+$BUNDLED_BRANDDIR/$brand}"; do
        [[ -n "$cand" ]] || continue
        if [[ -f "$cand/template.yaml" ]]; then
            brand_dir="$cand"
            brand_file="$cand/template.yaml"
            break
        fi
    done
    if [[ -z "$brand_file" ]]; then
        local legacy="${BRANDDIR}/brand-${brand}.yaml"
        if [[ -f "$legacy" ]]; then
            brand_file="$legacy"
            brand_dir="$BRANDDIR"
        else
            echo "Warning: Brand '$brand' not found in $BRANDDIR or bundled defaults" >&2
            return 1
        fi
    fi

    debug_log "Loading brand config: $brand_file"

    # The brand folder holds this brand's assets (logos, cover PDFs). Expose it so
    # the pandoc invocation can add it to the graphics/resource search paths.
    BRAND_ASSET_DIR="$brand_dir"

    # Read brand content
    local brand_content
    brand_content=$(cat "$brand_file")

    # Prepend brand config before document content
    # This way document settings override brand defaults
    MDCONTENT="${brand_content}"$'\n\n'"${MDCONTENT}"

    log_message "Loaded brand config: $brand"

    # Check for brand-specific Lua filter (folder layout, then legacy)
    local brand_lua="${brand_dir}/filter.lua"
    [[ -f "$brand_lua" ]] || brand_lua="${BRANDDIR}/brand-${brand}.lua"
    if [[ -f "$brand_lua" ]]; then
        debug_log "Found brand Lua filter: $brand_lua"
        BRAND_LUA="$brand_lua"
        log_message "Loaded brand Lua filter: $brand"
    fi

    return 0
}

extract_metadata() {
    # Parse the first YAML front-matter block with a real YAML parser, driven by
    # the META_FIELDS registry. This correctly handles quoted colons, multi-line
    # scalars, and booleans, and never mistakes a YAML example in a fenced code
    # block for front matter.
    local helper
    if ! helper=$(find_helper extract-frontmatter.pl); then
        echo "Warning: extract-frontmatter.pl helper not found; front matter not parsed" >&2
        return 0
    fi
    if ! command -v perl >/dev/null 2>&1; then
        echo "Warning: perl not available; front matter not parsed" >&2
        return 0
    fi

    # The helper emits NUL-delimited "yamlkey=value" records for the requested
    # keys. Map each YAML key onto its registered shell variable.
    local rec yamlkey val var
    while IFS= read -r -d '' rec; do
        yamlkey=${rec%%=*}
        val=${rec#*=}
        var=${META_FIELDS[$yamlkey]}
        [[ -n $var ]] && printf -v "$var" '%s' "$val"
    done < <(printf '%s' "$MDCONTENT" | perl "$helper" "${!META_FIELDS[@]}")

    debug_log "Parsed front matter: DOC_BRAND='$DOC_BRAND' DOC_TITLE='$DOC_TITLE' DOC_P_TEMPLATE='$DOC_P_TEMPLATE' DOC_DATE='$DOC_DATE' DOC_PRINTREADY='$DOC_PRINTREADY'"
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

    # Resolve brand-local and working-directory assets (logos, cover PDFs, images).
    # pandoc --resource-path covers Markdown images; TEXINPUTS covers LaTeX
    # \includegraphics / titlepage-background used by the template.
    local resource_path="$WD"
    [[ -n "$BRAND_ASSET_DIR" ]] && resource_path="${BRAND_ASSET_DIR}:${resource_path}"
    if [[ -n "$BRAND_ASSET_DIR" ]]; then
        export TEXINPUTS="${BRAND_ASSET_DIR}:${TEXINPUTS}"
        debug_log "Brand assets on path: $BRAND_ASSET_DIR"
    fi

    # Build the complete pandoc command
    local pandoc_cmd="pandoc $pandoc_debug $(load_filters) $lua_filters --resource-path=\"$resource_path\" --pdf-engine=\"$P_ENGINE\" ${P_TEMPLATE} $P_TLD --metadata=date:\"$DOC_DATE\" -f markdown+inline_notes \"$contentfile\" -t pdf -o \"$dstfile\""

    # Run pandoc
    if pandoc $pandoc_debug \
        $(eval echo "$lua_filters") \
        --resource-path="$resource_path" \
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
    # Let templates \input shared includes (e.g. pipeline-preamble.tex) from the
    # templates directory. Trailing colon preserves the default search path.
    export TEXINPUTS="${INCDIR}:${TEXINPUTS:-}"
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
    print_brands_hint
    
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
