-- document-filters.lua
-- Combined Pandoc Lua filter for charts and boxes with shared brand colour system
--
-- Reads brand colours from YAML metadata:
--
--   brand-colours:
--     tprf-blue: "3B7A9E"
--     tprf-orange: "E08A52"
--
--   chart-colours:        (ordered list of brand-colour names for chart segments)
--     - tprf-blue
--     - tprf-orange
--
--   box-colours:          (semantic names mapped to LaTeX colour expressions)
--     frame-info: tprf-green!90
--     bg-info: tprf-blue-light!10
--     frame-accent: tprf-blue!90
--     bg-accent: tprf-blue-light!10
--     frame-highlight: tprf-blue!90
--     bg-highlight: tprf-blue-light!10
--     frame-contrast: tprf-maroon!90
--     bg-contrast: tprf-maroon-light!10
--
-- Chart styles:
--   full:   left-aligned, full text width (default)
--   medium: centred minipage, 55% text width
--   margin: in page margin, no legend, scaled to fit

-- ===============================================================
-- Shared colour system
-- ===============================================================

-- brand-colours: name -> hex
local brand_colours = {}

-- chart-colours: ordered list of hex values for chart segments
local chart_palette = {}

-- box-colours: semantic name -> LaTeX colour expression
local box_colours = {}

-- Default chart palette (used when no chart-colours defined)
local default_chart_palette = {
  "4E79A7", "F28E2B", "E15759", "76B7B2",
  "59A14F", "EDC948", "B07AA1", "FF9DA7",
  "9C755F", "BAB0AC"
}

-- Default box colours (used when no box-colours defined)
local default_box_colours = {
  ["frame-info"]      = "SeaGreen!90",
  ["bg-info"]         = "LightBlue!10",
  ["frame-accent"]    = "RoyalPurple!90",
  ["bg-accent"]       = "LightBlue!10",
  ["frame-highlight"] = "CadetBlue!90",
  ["bg-highlight"]    = "LightBlue!10",
  ["frame-contrast"]  = "IndianRed!90",
  ["bg-contrast"]     = "Lavender!10",
}

-- Recommendation counter (global state across Div calls)
local recommendationCounter = 0

-- ---------------------------------------------------------------
-- Metadata reader
-- ---------------------------------------------------------------

local function read_meta(meta)

  -- Read brand-colours: name -> hex mapping
  if meta["brand-colours"] then
    -- Handle both MetaMap and MetaList formats
    local bc = meta["brand-colours"]
    if type(bc) == "table" then
      for k, v in pairs(bc) do
        if type(k) == "string" then
          brand_colours[k] = pandoc.utils.stringify(v)
        end
      end
    end
  end

  -- Read chart-colours: ordered list of brand-colour names
  if meta["chart-colours"] then
    local cc = meta["chart-colours"]
    if type(cc) == "table" then
      for _, item in ipairs(cc) do
        local name = pandoc.utils.stringify(item)
        -- Resolve to hex via brand-colours, or use directly if it looks like hex
        if brand_colours[name] then
          table.insert(chart_palette, brand_colours[name])
        elseif name:match("^%x%x%x%x%x%x$") then
          table.insert(chart_palette, name)
        end
      end
    end
  end

  -- Fall back to default chart palette if nothing defined
  if #chart_palette == 0 then
    for _, hex in ipairs(default_chart_palette) do
      table.insert(chart_palette, hex)
    end
  end

  -- Read box-colours: semantic name -> LaTeX colour expression
  if meta["box-colours"] then
    local bc = meta["box-colours"]
    if type(bc) == "table" then
      for k, v in pairs(bc) do
        if type(k) == "string" then
          box_colours[k] = pandoc.utils.stringify(v)
        end
      end
    end
  end

  -- Fill in any missing box colours with defaults
  for k, v in pairs(default_box_colours) do
    if not box_colours[k] then
      box_colours[k] = v
    end
  end

  -- ---------------------------------------------------------------
  -- Resolve brand-colour references in metadata fields that expect
  -- hex colour values. These fields are consumed by templates like
  -- Eisvogel which expect raw hex (e.g. "3B7A9E").
  -- If the value matches a brand-colour name, replace with its hex.
  -- Also supports "white" and "black" as convenience aliases.
  -- ---------------------------------------------------------------
  local colour_meta_fields = {
    "titlepage-color",
    "titlepage-text-color",
    "titlepage-rule-color",
    "page-background-color",
    "header-color",
    "footer-color",
  }

  local convenience_colours = {
    white   = "FFFFFF",
    black   = "000000",
  }

  for _, field in ipairs(colour_meta_fields) do
    if meta[field] then
      local val = pandoc.utils.stringify(meta[field])
      if brand_colours[val] then
        meta[field] = pandoc.MetaInlines({pandoc.Str(brand_colours[val])})
      elseif convenience_colours[val:lower()] then
        meta[field] = pandoc.MetaInlines({pandoc.Str(convenience_colours[val:lower()])})
      end
    end
  end

  -- ---------------------------------------------------------------
  -- Auto-generate \definecolor lines from brand-colours and inject
  -- into header-includes. This means brand-colour names can be used
  -- directly in LaTeX (\color{tprf-blue}, \colorbox{onion-3}, etc.)
  -- without manual \definecolor lines in the YAML.
  -- ---------------------------------------------------------------
  if next(brand_colours) then
    -- Build sorted list for deterministic output order
    local sorted_names = {}
    for name, _ in pairs(brand_colours) do
      table.insert(sorted_names, name)
    end
    table.sort(sorted_names)

    -- Build LaTeX \definecolor block
    local colour_defs = {}
    for _, name in ipairs(sorted_names) do
      table.insert(colour_defs, string.format(
        "\\definecolor{%s}{HTML}{%s}", name, brand_colours[name]
      ))
    end
    local colour_block = table.concat(colour_defs, "\n")

    -- Inject into header-includes (prepend so colours are available
    -- to any subsequent header-includes content)
    local raw_block = pandoc.RawBlock("latex", colour_block)

    if meta["header-includes"] then
      -- header-includes can be MetaBlocks or MetaList
      local hi = meta["header-includes"]
      if hi.t == "MetaBlocks" then
        -- Single block: wrap in list with colour defs first
        meta["header-includes"] = pandoc.MetaList({
          pandoc.MetaBlocks({raw_block}),
          hi
        })
      elseif hi.t == "MetaList" then
        -- Already a list: prepend
        table.insert(hi, 1, pandoc.MetaBlocks({raw_block}))
      else
        -- Unknown format: wrap both
        meta["header-includes"] = pandoc.MetaList({
          pandoc.MetaBlocks({raw_block}),
          hi
        })
      end
    else
      meta["header-includes"] = pandoc.MetaBlocks({raw_block})
    end
  end

  -- ---------------------------------------------------------------
  -- Datatable rowspans emit \multirow (see make_datatable), but the
  -- package is never guaranteed to be loaded: the Eisvogel templates
  -- only load it under $if(tables)$$if(multirow)$, and pandoc sets
  -- neither variable for our raw-LaTeX datatables. Inject the
  -- requirement straight into header-includes so it is loaded for any
  -- template, avoiding "Undefined control sequence ... \multirow".
  -- ---------------------------------------------------------------
  local pkg_block = pandoc.RawBlock("latex", "\\usepackage{multirow}\n\\usepackage{array}")
  if meta["header-includes"] then
    local hi = meta["header-includes"]
    if hi.t == "MetaList" then
      table.insert(hi, pandoc.MetaBlocks({pkg_block}))
    else
      meta["header-includes"] = pandoc.MetaList({
        hi,
        pandoc.MetaBlocks({pkg_block})
      })
    end
  else
    meta["header-includes"] = pandoc.MetaBlocks({pkg_block})
  end

  return meta
end

-- ---------------------------------------------------------------
-- Shared helpers
-- ---------------------------------------------------------------

local function trim(s)
  return s:match("^%s*(.-)%s*$")
end

-- Resolve a chart colour by index (1-based, cycles through palette)
local function chart_colour_hex(index)
  local idx = ((index - 1) % #chart_palette) + 1
  return chart_palette[idx]
end

-- Get a box colour by semantic name
local function box_colour(name)
  return box_colours[name] or "black"
end

-- Generate \definecolor lines for chart colours
local function chart_colour_definitions(count)
  local lines = {}
  for i = 1, count do
    table.insert(lines, string.format(
      "\\definecolor{chartcol%d}{HTML}{%s}", i, chart_colour_hex(i)
    ))
  end
  return table.concat(lines, "\n")
end

-- Sanitise a label string for use in pgf-pie / pgfplots
local function sanitise_label(s)
  s = s:gsub("\\%(", "(")
  s = s:gsub("\\%)", ")")
  s = s:gsub("&", "\\&")
  s = s:gsub("%%", "\\%%")
  s = s:gsub("#", "\\#")
  s = s:gsub("_", "\\_")
  s = s:gsub("%$", "\\$")
  s = s:gsub(",", ";")
  return "\\mbox{" .. s .. "}"
end

-- Sanitise a caption string for LaTeX
local function sanitise_caption(s)
  s = s:gsub("\\%(", "(")
  s = s:gsub("\\%)", ")")
  s = s:gsub("%$", "\\$")
  s = s:gsub("&", "\\&")
  s = s:gsub("%%", "\\%%")
  s = s:gsub("#", "\\#")
  s = s:gsub("_", "\\_")
  return s
end

-- Sanitise prefix/postfix for LaTeX contexts
local function sanitise_affix(s)
  s = s:gsub("%$", "\\$")
  return s
end

-- Resolve style from opts, accepting aliases
local function resolve_style(opts)
  local raw = (opts["style"] or opts["size"] or "full"):lower()
  if raw == "flow" or raw == "flow-mini" then
    return "medium"
  end
  if raw == "medium" or raw == "margin" then
    return raw
  end
  return "full"
end

-- Parse chart code block text into opts table and entries list
local function parse_chart_block(text)
  local opts = {}
  local entries = {}

  for line in text:gmatch("[^\r\n]+") do
    line = trim(line)
    if line ~= "" then
      local key, val = line:match("^(%a[%a%-]*):%s*(.+)$")
      if key and not tonumber(val) then
        opts[key:lower()] = trim(val)
      else
        local label, num = line:match("^(.-):%s*([%d%.]+)%s*$")
        if label and num then
          table.insert(entries, { label = trim(label), value = tonumber(num) })
        end
      end
    end
  end

  return opts, entries
end

-- ===============================================================
-- Chart filter
-- ===============================================================

-- Estimate chart height in cm for Needspace
local function estimate_chart_height(chart_type, entry_count, axis_dir, style)
  local base
  if chart_type == "pie" then
    if style == "margin" then
      base = 5.0
    else
      base = 6.0 + (entry_count * 0.5)
    end
  elseif axis_dir == "H" then
    base = math.max(entry_count * 1.4, 5) + 2.0
  else
    base = 10.0
  end
  if style == "medium" then
    base = base * 0.8
  end
  return base + 1.5
end

-- Wrap chart content in layout container
local function figure_wrap(content, opts, chart_type, entry_count)
  local style = resolve_style(opts)
  local caption = opts["caption"]
  if caption then
    caption = sanitise_caption(caption)
  end
  local axis_dir = (opts["axis"] or "H"):upper()
  local needspace = estimate_chart_height(chart_type, entry_count, axis_dir, style)
  local lines = {}

  if style == "margin" then
    table.insert(lines, string.format("\\Needspace{%.1fcm}", needspace))
    table.insert(lines, "\\pwMarginNoteWidth")
    table.insert(lines, "\\checkoddpage")
    table.insert(lines, "\\ifoddpage")
    table.insert(lines, "\\marginnote{%")
    table.insert(lines, "  \\resizebox{\\marginparwidth}{!}{%")
    table.insert(lines, content)
    table.insert(lines, "  }%")
    if caption then
      table.insert(lines, string.format(
        "  \\par\\vspace{2pt}{\\scriptsize %s}", caption
      ))
    end
    table.insert(lines, "}%")
    table.insert(lines, "\\else")
    table.insert(lines, "\\marginnote{%")
    table.insert(lines, "  \\resizebox{\\marginparwidth}{!}{%")
    table.insert(lines, content)
    table.insert(lines, "  }%")
    if caption then
      table.insert(lines, string.format(
        "  \\par\\vspace{2pt}{\\scriptsize %s}", caption
      ))
    end
    table.insert(lines, "}%")
    table.insert(lines, "\\fi")

  elseif style == "medium" then
    table.insert(lines, "\\vspace{0.5em}")
    table.insert(lines, string.format("\\Needspace{%.1fcm}", needspace))
    table.insert(lines, "\\begin{center}")
    table.insert(lines, "\\begin{minipage}{0.55\\textwidth}")
    table.insert(lines, "  \\centering")
    table.insert(lines, "  \\resizebox{\\linewidth}{!}{%")
    table.insert(lines, content)
    table.insert(lines, "  }%")
    if caption then
      table.insert(lines, string.format(
        "  \\par\\vspace{4pt}\\captionof{figure}{%s}", caption
      ))
    end
    table.insert(lines, "\\end{minipage}")
    table.insert(lines, "\\end{center}")
    table.insert(lines, "\\vspace{1em}")

  else
    table.insert(lines, "\\vspace{1em}")
    table.insert(lines, string.format("\\Needspace{%.1fcm}", needspace))
    table.insert(lines, "\\noindent")
    table.insert(lines, "\\begin{flushleft}")
    table.insert(lines, "\\resizebox{\\linewidth}{!}{%")
    table.insert(lines, content)
    table.insert(lines, "}%")
    if caption then
      table.insert(lines, string.format(
        "\\par\\vspace{4pt}\\captionof{figure}{%s}", caption
      ))
    end
    table.insert(lines, "\\end{flushleft}")
    table.insert(lines, "\\vspace{1em}")
  end

  return table.concat(lines, "\n")
end

-- Generate pie chart LaTeX
local function make_pie(opts, entries)
  local style = resolve_style(opts)
  local lines = {}

  table.insert(lines, chart_colour_definitions(#entries))
  table.insert(lines, "")

  local pie_items = {}
  local colour_list = {}
  for i, e in ipairs(entries) do
    if style == "margin" then
      table.insert(pie_items, string.format("%s/", e.value))
    else
      table.insert(pie_items, string.format(
        "%s/%s", e.value, sanitise_label(e.label)
      ))
    end
    table.insert(colour_list, string.format("chartcol%d", i))
  end

  local before = sanitise_affix(opts["prefix"]  or "")
  local after  = sanitise_affix(opts["postfix"] or "")

  local scale, radius
  if style == "margin" then
    scale = "0.45"
    radius = "3"
  elseif style == "medium" then
    scale = "0.8"
    radius = "3"
  else
    scale = "1.0"
    radius = "4"
  end

  local text_opt = (style == "margin") and "inside" or "legend"

  table.insert(lines, string.format("\\begin{tikzpicture}[scale=%s]", scale))
  table.insert(lines, string.format(
    "\\pie[color={%s}, before number={%s}, after number={%s}, text=%s, radius=%s]{",
    table.concat(colour_list, ", "), before, after, text_opt, radius
  ))
  table.insert(lines, "  " .. table.concat(pie_items, ",\n  "))
  table.insert(lines, "}")
  table.insert(lines, "\\end{tikzpicture}")

  return figure_wrap(table.concat(lines, "\n"), opts, "pie", #entries)
end

-- Generate bar chart LaTeX
local function make_bar(opts, entries)
  local axis_dir = (opts["axis"] or "H"):upper()
  local style = resolve_style(opts)
  local lines = {}

  table.insert(lines, chart_colour_definitions(#entries))
  table.insert(lines, "")

  local scale = (style == "medium") and "0.8" or "1.0"
  local prefix  = sanitise_affix(opts["prefix"]  or "")
  local postfix = sanitise_affix(opts["postfix"] or "")

  local labels = {}
  for _, e in ipairs(entries) do
    table.insert(labels, sanitise_label(e.label))
  end

  local max_val = 0
  for _, e in ipairs(entries) do
    if e.value > max_val then max_val = e.value end
  end
  local headroom = math.ceil(max_val * 1.25)

  local height
  if axis_dir == "H" then
    height = tostring(math.max(#entries * 1.4, 5)) .. "cm"
  else
    height = "8cm"
  end

  table.insert(lines, string.format("\\begin{tikzpicture}[scale=%s]", scale))
  table.insert(lines, "\\begin{axis}[")
  table.insert(lines, "  clip=false,")

  if axis_dir == "H" then
    table.insert(lines, "  xbar,")
    table.insert(lines, "  bar width=14pt,")
    table.insert(lines, "  bar shift=0pt,")
    table.insert(lines, "  enlarge y limits={abs=0.8cm},")
    table.insert(lines, "  xlabel={},")
    table.insert(lines, "  xmin=0,")
    table.insert(lines, string.format("  xmax=%s,", headroom))
    table.insert(lines, string.format("  symbolic y coords={%s},", table.concat(labels, ", ")))
    table.insert(lines, "  ytick=data,")
    table.insert(lines, "  y tick label style={font=\\small},")
    table.insert(lines, "  nodes near coords style={font=\\small, anchor=west},")
  else
    table.insert(lines, "  ybar,")
    table.insert(lines, "  bar width=14pt,")
    table.insert(lines, "  bar shift=0pt,")
    table.insert(lines, "  enlarge x limits={abs=1.2cm},")
    table.insert(lines, "  ylabel={},")
    table.insert(lines, "  ymin=0,")
    table.insert(lines, string.format("  ymax=%s,", headroom))
    table.insert(lines, string.format("  symbolic x coords={%s},", table.concat(labels, ", ")))
    table.insert(lines, "  xtick=data,")
    table.insert(lines, "  x tick label style={font=\\small, rotate=45, anchor=east},")
    table.insert(lines, "  nodes near coords style={font=\\small, rotate=90, anchor=west},")
  end

  if prefix ~= "" or postfix ~= "" then
    table.insert(lines, string.format(
      "  nodes near coords={%s\\pgfmathprintnumber{\\pgfplotspointmeta}%s},",
      prefix, postfix
    ))
    table.insert(lines, "  point meta=explicit,")
  else
    table.insert(lines, "  nodes near coords,")
  end

  table.insert(lines, "  width=\\textwidth,")
  table.insert(lines, string.format("  height=%s,", height))
  table.insert(lines, "  legend style={draw=none},")
  table.insert(lines, "  cycle list={")
  for i = 1, #entries do
    local sep = (i < #entries) and "," or ""
    table.insert(lines, string.format("    {fill=chartcol%d, draw=chartcol%d!80!black}%s", i, i, sep))
  end
  table.insert(lines, "  },")
  table.insert(lines, "]")

  for i, e in ipairs(entries) do
    local safe_label = sanitise_label(e.label)
    local meta_str = ""
    if prefix ~= "" or postfix ~= "" then
      meta_str = string.format(" [%s]", e.value)
    end
    local coord
    if axis_dir == "H" then
      coord = string.format("(%s,%s)%s", e.value, safe_label, meta_str)
    else
      coord = string.format("(%s,%s)%s", safe_label, e.value, meta_str)
    end
    table.insert(lines, string.format("\\addplot coordinates {%s};", coord))
  end

  table.insert(lines, "\\end{axis}")
  table.insert(lines, "\\end{tikzpicture}")

  return figure_wrap(table.concat(lines, "\n"), opts, "bar", #entries)
end

-- CodeBlock handler for charts
local function handle_chart(el)
  local chart_type = nil

  if el.classes[1] == "piechart" then
    chart_type = "pie"
  elseif el.classes[1] == "barchart" then
    chart_type = "bar"
  end

  if not chart_type then
    return nil
  end

  local opts, entries = parse_chart_block(el.text)

  if #entries == 0 then
    return nil
  end

  local latex
  if chart_type == "pie" then
    latex = make_pie(opts, entries)
  else
    latex = make_bar(opts, entries)
  end

  local preamble = ""
  if chart_type == "pie" then
    preamble = "% Requires: \\usepackage{pgf-pie}\n"
  else
    preamble = "% Requires: \\usepackage{pgfplots}\n"
  end

  return pandoc.RawBlock("latex", preamble .. latex)
end

-- ===============================================================
-- Box filter
-- ===============================================================

local function handle_box(el)

  -- Compute vertical space based on character count per line
  local text = pandoc.utils.stringify(el)
  local charCount = 0
  local charsPerLine = 0

  for _ in string.gmatch(text, ".") do
    charCount = charCount + 1
  end

  if el.classes:includes("textbox") then
    charsPerLine = 30
  elseif el.classes:includes("recommendation") then
    charsPerLine = 65
  elseif el.classes:includes("widebox") then
    charsPerLine = 70
  elseif el.classes:includes("marginbox") then
    charsPerLine = 16
  elseif el.classes:includes("examplebox") then
    charsPerLine = 65
  elseif el.classes:includes("budgetbox") then
    charsPerLine = 65
  elseif el.classes:includes("box-policysummary") then
    charsPerLine = 65
  else
    return nil  -- not a recognised box type
  end

  local charLines = math.ceil(charCount / charsPerLine)
  local lineHeight = 0.7

  -- Box-type-specific needspace
  local needspace_cm = 0

  if el.classes:includes("marginbox") then
    needspace_cm = math.max((charLines * lineHeight) + 0.5, 2.5)
  elseif el.classes:includes("textbox") then
    needspace_cm = math.max((charLines * lineHeight) + 1.0, 3.0)
  else
    needspace_cm = math.max((charLines * lineHeight) + 2.0, 4.0)
  end

  -- Convert Div content to LaTeX
  local doc = pandoc.Pandoc(el.content)
  local full_content = pandoc.write(doc, "latex")
  local content = full_content:match("\\begin{document}(.*)\\end{document}")
  if not content then
    content = full_content
  end
  content = content:gsub("^%s+", ""):gsub("%s+$", "")

  -- ---------------------------------------------------------------
  -- textbox: wrapped text box covering 60% of the page
  -- ---------------------------------------------------------------
  if el.classes:includes("textbox") then
    local latex = string.format([[
\Needspace{%scm}
\setlength{\intextsep}{3pt}
\begin{wrapfigure}{r}{0.6\textwidth}%%
  \hspace*{-1cm}%%
  \begin{tcolorbox}[
  colframe=%s,
  colback=%s,
  boxrule=2pt,
  arc=2mm,
  auto outer arc,
  left=3mm,
  right=3mm,
  width=\linewidth
]
\setlength{\parskip}{1.0em}
\faInfoCircle\hspace{0.5em}
%s
  \end{tcolorbox}
\end{wrapfigure}
]], needspace_cm, box_colour("frame-info"), box_colour("bg-info"), content)

    return pandoc.RawBlock("latex", latex)

  -- ---------------------------------------------------------------
  -- recommendation: numbered recommendation boxes
  -- ---------------------------------------------------------------
  elseif el.classes:includes("recommendation") then
    recommendationCounter = recommendationCounter + 1
    local anchor = "recommendation-" .. tostring(recommendationCounter)
    local counterStr = tostring(recommendationCounter)

    local latex = string.format([[
\vspace{1em}
\Needspace{%scm}
\begin{tcolorbox}[
  colframe=%s,
  colback=%s,
  boxrule=0pt,
  leftrule=2pt,
  sharp corners,
  left=3mm,
  right=3mm,
  width=\linewidth,
]
  \hypertarget{%s}{}
  {\bfseries\setlength{\parskip}{1.0em} Recommendation %s: }\par{

%s

}
  \end{tcolorbox}
]], needspace_cm, box_colour("frame-accent"), box_colour("bg-accent"),
    anchor, counterStr, content)

    return pandoc.RawBlock("latex", latex)

  -- ---------------------------------------------------------------
  -- examplebox: evidence and examples
  -- ---------------------------------------------------------------
  elseif el.classes:includes("examplebox") then
    local latex = string.format([[
\vspace{1em}
\Needspace{%scm}
\begin{tcolorbox}[
  colframe=%s,
  colback=%s,
  boxrule=0pt,
  leftrule=2pt,
  sharp corners,
  left=3mm,
  right=3mm,
  width=\linewidth,
]
\faBookOpen\hspace{0.5em}
%s
  \end{tcolorbox}
]], needspace_cm, box_colour("frame-accent"), box_colour("bg-accent"), content)

    return pandoc.RawBlock("latex", latex)

  -- ---------------------------------------------------------------
  -- box-policysummary: policy concept summaries
  -- ---------------------------------------------------------------
  elseif el.classes:includes("box-policysummary") then
    local latex = string.format([[
\vspace{1em}
\Needspace{%scm}
\begin{tcolorbox}[
  colframe=%s,
  colback=%s,
  boxrule=0pt,
  leftrule=2pt,
  sharp corners,
  left=3mm,
  right=3mm,
  width=\linewidth,
]
{\bfseries\setlength{\parskip}{1.0em}\faBalanceScale\hspace{0.5em} Policy concept summary }\par{
  %s
  }
  \end{tcolorbox}
]], needspace_cm, box_colour("frame-accent"), box_colour("bg-contrast"), content)

    return pandoc.RawBlock("latex", latex)

  -- ---------------------------------------------------------------
  -- budgetbox: budget proposals
  -- ---------------------------------------------------------------
  elseif el.classes:includes("budgetbox") then
    local latex = string.format([[
\vspace{1em}
\Needspace{%scm}
\begin{tcolorbox}[
  colframe=%s,
  colback=%s,
  boxrule=0pt,
  leftrule=2pt,
  sharp corners,
  left=3mm,
  right=3mm,
  width=\linewidth,
]
{\bfseries\setlength{\parskip}{1.0em}\faEuroSign\hspace{0.5em} Budgetary proposal }\par{
  %s
  }
  \end{tcolorbox}
]], needspace_cm, box_colour("frame-contrast"), box_colour("bg-info"), content)

    return pandoc.RawBlock("latex", latex)

  -- ---------------------------------------------------------------
  -- widebox: full-width emphasis box
  -- ---------------------------------------------------------------
  elseif el.classes:includes("widebox") then
    local latex = string.format([[
\vspace{1em}
\Needspace{%scm}
\begin{tcolorbox}[
  colframe=%s,
  colback=%s,
  boxrule=2pt,
  arc=2mm,
  auto outer arc,
  left=3mm,
  right=3mm,
  width=\linewidth
]
{\setlength{\parskip}{1.0em}
%s }
\end{tcolorbox}
]], needspace_cm, box_colour("frame-highlight"), box_colour("bg-highlight"), content)

    return pandoc.RawBlock("latex", latex)

  -- ---------------------------------------------------------------
  -- marginbox: margin quotes and highlights
  -- ---------------------------------------------------------------
  elseif el.classes:includes("marginbox") then
    local latex = string.format([[
\Needspace{%scm}
  \pwMarginNoteWidth
  \checkoddpage
  \ifoddpage
  \marginnote{
    \begin{tcolorbox}[
      colframe=%s,
      boxrule=0pt,
      leftrule=2pt,
      sharp corners,
      left=1mm,
      right=1mm,
    ]
    \raggedright\setlength{\parskip}{1.0em}
    %s
    \end{tcolorbox}
  }
  \else
    \marginnote{
    \begin{tcolorbox}[
      colframe=%s,
      boxrule=0pt,
      rightrule=2pt,
      sharp corners,
      left=1mm,
      right=1mm,
    ]
    \raggedleft\setlength{\parskip}{1.0em}
    %s
    \end{tcolorbox}
  }
  \fi
]], needspace_cm, box_colour("frame-contrast"), content,
    box_colour("frame-contrast"), content)

    return pandoc.RawBlock("latex", latex)
  end
end

-- ===============================================================
-- Datatable filter
-- ===============================================================

-- Convert markdown bold **text** to \textbf{text} for LaTeX cell content
local function md_to_latex_cell(s)
  -- Process **bold** markers
  s = s:gsub("%*%*(.-)%*%*", "\\textbf{%1}")
  -- Escape LaTeX specials (but not \ from our \textbf above)
  -- We need to escape before converting bold, so do it carefully:
  -- Actually, escape first then convert bold on the escaped text
  -- Rewrite: escape then bold
  return s
end

-- Escape LaTeX specials in cell text, then convert markdown bold
local function process_cell(s)
  s = trim(s)
  -- Extract bold markers, escape the rest, then re-insert bold
  -- Strategy: replace **...** with placeholders, escape, restore
  local bolds = {}
  local idx = 0
  s = s:gsub("%*%*(.-)%*%*", function(inner)
    idx = idx + 1
    bolds[idx] = inner
    return "\x00BOLD" .. idx .. "\x00"
  end)

  -- Escape LaTeX specials
  s = s:gsub("&", "\\&")
  s = s:gsub("%%", "\\%%")
  s = s:gsub("#", "\\#")
  s = s:gsub("_", "\\_")
  s = s:gsub("%$", "\\$")

  -- Restore bold markers as \textbf
  s = s:gsub("\x00BOLD(%d+)\x00", function(n)
    local inner = bolds[tonumber(n)]
    -- Escape specials inside bold too
    inner = inner:gsub("&", "\\&")
    inner = inner:gsub("%%", "\\%%")
    inner = inner:gsub("#", "\\#")
    inner = inner:gsub("_", "\\_")
    inner = inner:gsub("%$", "\\$")
    return "\\textbf{" .. inner .. "}"
  end)

  return s
end

-- Parse datatable code block
local function parse_datatable(text)
  local opts = {}
  local rows = {}
  local in_data = false

  for line in text:gmatch("[^\r\n]+") do
    if not in_data then
      -- Check for separator
      if line:match("^%-%-%-") then
        in_data = true
      else
        local key, val = line:match("^(%a[%a%-]*):%s*(.+)$")
        if key then
          opts[key:lower()] = trim(val)
        end
      end
    else
      -- Data row: skip blank lines
      local trimmed = trim(line)
      if trimmed ~= "" then
        local cells = {}
        for cell in (trimmed .. "|"):gmatch("(.-)%s*|") do
          table.insert(cells, trim(cell))
        end
        table.insert(rows, cells)
      end
    end
  end

  return opts, rows
end

-- Resolve tone to header and row colour expressions
local function resolve_tone(tone_str)
  local tone = (tone_str or "medium"):lower()
  local header_pct, row_pct

  if tone == "grey" then
    return "black!60", "black!4", nil
  elseif tone == "light" then
    header_pct = 30
    row_pct = 3
  elseif tone == "medium" then
    header_pct = 60
    row_pct = 5
  elseif tone == "strong" then
    header_pct = 90
    row_pct = 8
  else
    -- Try to parse as number
    local num = tonumber(tone)
    if num then
      header_pct = num
      row_pct = math.max(math.floor(num / 10), 2)
    else
      header_pct = 60
      row_pct = 5
    end
  end

  -- Use first chart colour as the accent for tables
  local accent_hex = chart_palette[1] or "4E79A7"
  local accent_name = "datatableaccent"

  return accent_name .. "!" .. header_pct,
         accent_name .. "!" .. row_pct,
         accent_hex
end

-- Compute rowspans: for each column, find runs of blank cells
-- Returns a 2D table: spans[row][col] = number of rows this cell spans
-- (0 means this cell is covered by a span above)
local function compute_rowspans(rows, num_cols)
  local spans = {}
  for r = 1, #rows do
    spans[r] = {}
    for c = 1, num_cols do
      spans[r][c] = 1
    end
  end

  for c = 1, num_cols do
    local anchor = 1
    for r = 2, #rows do
      if rows[r][c] == nil or rows[r][c] == "" then
        -- Blank cell: extend the anchor's span
        spans[anchor][c] = spans[anchor][c] + 1
        spans[r][c] = 0  -- covered
      else
        anchor = r
      end
    end
  end

  return spans
end

-- Build longtable LaTeX from parsed datatable
local function make_datatable(opts, rows)
  if #rows == 0 then return "" end

  -- Parse options
  local col_headers = {}
  if opts["columns"] then
    for h in (opts["columns"] .. "|"):gmatch("(.-)%s*|") do
      table.insert(col_headers, trim(h))
    end
  end
  local num_cols = #col_headers
  if num_cols == 0 then
    -- Infer from first data row
    num_cols = #rows[1]
    for i = 1, num_cols do
      col_headers[i] = ""
    end
  end

  -- Parse widths
  local widths = {}
  if opts["widths"] then
    for w in (opts["widths"] .. "|"):gmatch("(.-)%s*|") do
      local tw = trim(w)
      if tw:upper() == "X" then
        table.insert(widths, "X")
      elseif tw:match("^[%d%.]+cm$") then
        table.insert(widths, "p{" .. tw .. "}")
      elseif tw:match("^[%d%.]+$") then
        table.insert(widths, "p{" .. tw .. "cm}")
      else
        table.insert(widths, "X")
      end
    end
  end
  -- Fill missing widths with X
  while #widths < num_cols do
    table.insert(widths, "X")
  end

  -- Parse bold columns
  local bold_cols = {}
  if opts["bold"] then
    for n in opts["bold"]:gmatch("(%d+)") do
      bold_cols[tonumber(n)] = true
    end
  end

  -- Parse text (prose) columns. A flexible (X) column listed here is weighted
  -- more heavily when the leftover width is shared out, so a prose-heavy column
  -- gets the room it needs instead of an equal slice that wraps every word.
  -- `text: 2` weights column 2 at x2; `text: 2*3` weights it x3.
  local text_weight = {}
  if opts["text"] then
    for col, mult in (opts["text"] .. ","):gmatch("%s*(%d+)%s*%*?(%d*)%s*,") do
      text_weight[tonumber(col)] = (mult ~= "" and tonumber(mult)) or 2
    end
  end

  -- Resolve tone
  local header_colour, row_colour, accent_hex = resolve_tone(opts["tone"])

  -- Calculate X column widths.
  -- Strategy: use @{} on outer edges to suppress outer tabcolsep,
  -- so the table fills exactly \textwidth. Internal padding between
  -- columns uses a small known gap via @{\hspace{4pt}}.
  -- X columns get: (\textwidth - fixed_total - (num_cols-1)*gap) / x_count
  local fixed_total = 0
  local x_count = 0
  local x_weight_total = 0
  for i, w in ipairs(widths) do
    if w == "X" then
      x_count = x_count + 1
      x_weight_total = x_weight_total + (text_weight[i] or 1)
    else
      local cm = w:match("p{([%d%.]+)cm}")
      if cm then fixed_total = fixed_total + tonumber(cm) end
    end
  end

  -- Inter-column gap count: num_cols - 1
  local gap_count = num_cols - 1

  -- Build column spec parts
  local col_spec_parts = {}
  for i, w in ipairs(widths) do
    local prefix = ">{\\raggedright\\arraybackslash}"
    if bold_cols[i] then
      prefix = ">{\\bfseries\\raggedright\\arraybackslash}"
    end
    if w == "X" then
      -- Each column has 2*\tabcolsep overhead (~4mm per column with 2mm tabcolsep).
      -- Subtract all column padding as a fixed cm amount.
      -- num_cols * 0.4cm is a safe estimate for 2mm tabcolsep.
      local padding_cm = num_cols * 0.4
      local subtract = fixed_total + padding_cm
      -- Share the leftover width by weight: equal slices by default, but a
      -- column flagged via `text:` claims a proportionally larger slice.
      local weight = text_weight[i] or 1
      col_spec_parts[i] = prefix .. string.format(
        "p{\\dimexpr(\\textwidth - %.1fcm) * %d / %d\\relax}",
        subtract, weight, x_weight_total
      )
    else
      col_spec_parts[i] = prefix .. w
    end
  end

  local col_spec = table.concat(col_spec_parts, " ")

  -- Compute rowspans
  local spans = compute_rowspans(rows, num_cols)

  -- Build LaTeX
  local lines = {}

  if accent_hex then
    table.insert(lines, string.format(
      "\\definecolor{datatableaccent}{HTML}{%s}", accent_hex
    ))
  end
  table.insert(lines, "\\begingroup")
  table.insert(lines, "\\small")
  -- Add vertical padding to rows via a strut in every first column
  -- This avoids touching \arraystretch which conflicts with some templates
  table.insert(lines, "\\newcommand{\\dtstrut}{\\rule{0pt}{2.4ex}}")
  table.insert(lines, string.format(
    "\\rowcolors{2}{%s}{white}", row_colour
  ))

  table.insert(lines, string.format(
    "\\begin{longtable}{%s}", col_spec
  ))

  -- Caption if present
  if opts["caption"] then
    table.insert(lines, string.format(
      "\\caption{%s}\\\\", sanitise_caption(opts["caption"])
    ))
  end

  -- Header row
  local header_cells = {}
  for i, h in ipairs(col_headers) do
    table.insert(header_cells, string.format(
      "\\textcolor{white}{\\textbf{%s}}", process_cell(h)
    ))
  end
  table.insert(lines, string.format("\\rowcolor{%s}", header_colour))
  table.insert(lines, "\\dtstrut " .. table.concat(header_cells, " &\n") .. " \\\\")
  table.insert(lines, "\\endfirsthead")

  -- Continuation header
  table.insert(lines, string.format("\\rowcolor{%s}", header_colour))
  table.insert(lines, "\\dtstrut " .. table.concat(header_cells, " &\n") .. " \\\\")
  table.insert(lines, "\\endhead")

  -- Continuation footer
  table.insert(lines, string.format(
    "\\multicolumn{%d}{r}{\\small\\textit{continued on next page}} \\\\",
    num_cols
  ))
  table.insert(lines, "\\endfoot")
  table.insert(lines, "\\endlastfoot")

  -- Data rows
  for r, row in ipairs(rows) do
    local cells = {}
    for c = 1, num_cols do
      if spans[r][c] == 0 then
        -- Covered by multirow above: emit empty cell
        table.insert(cells, "")
      elseif spans[r][c] > 1 then
        -- Start of a multirow span
        local content = process_cell(row[c] or "")
        local span_count = spans[r][c]
        -- = uses the column p{} width for word wrapping
        -- [t] aligns to top of the span instead of vertical centre
        table.insert(cells, string.format(
          "\\multirow[t]{%d}{=}{%s}", span_count, content
        ))
      else
        -- Normal cell
        table.insert(cells, process_cell(row[c] or ""))
      end
    end
    -- Add strut to first cell for consistent row height
    if cells[1] then
      cells[1] = "\\dtstrut " .. cells[1]
    end
    table.insert(lines, table.concat(cells, " & ") .. " \\\\")
  end

  table.insert(lines, "\\end{longtable}")
  table.insert(lines, "\\endgroup")

  return table.concat(lines, "\n")
end

-- CodeBlock handler for datatables
local function handle_datatable(el)
  if el.classes[1] ~= "datatable" then
    return nil
  end

  local opts, rows = parse_datatable(el.text)
  if #rows == 0 then return nil end

  local latex = make_datatable(opts, rows)
  return pandoc.RawBlock("latex",
    "% Requires: \\usepackage{longtable,multirow,array,xcolor}\n" .. latex
  )
end

-- ===============================================================
-- Filter sequence
-- ===============================================================

-- Combined CodeBlock handler
local function handle_codeblock(el)
  if el.classes[1] == "datatable" then
    return handle_datatable(el)
  else
    return handle_chart(el)
  end
end

return {
  { Meta = read_meta },
  { CodeBlock = handle_codeblock, Div = handle_box }
}
