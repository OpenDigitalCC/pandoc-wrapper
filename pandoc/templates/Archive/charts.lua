-- chart-filter.lua
-- Pandoc Lua filter for embedding pie and bar charts via pgf-pie and pgfplots
--
-- Usage in markdown:
--
--   ```piechart
--   colours: brand-blue, brand-orange, brand-green
--   caption: Spending by category
--   style: full
--   prefix: $
--   postfix: %
--   Perl Core Maintenance: 54
--   Events: 16
--   ```
--
--   ```barchart
--   colours: brand-blue, brand-orange
--   caption: Revenue breakdown
--   axis: H
--   style: medium
--   postfix: %
--   Category A: 40
--   Category B: 60
--   ```
--
-- Style modes:
--   full:   left-aligned, full text width (default)
--   medium: centred minipage, 55% text width
--   margin: in page margin, no legend, scaled to fit
--
-- Colours are defined in YAML front matter:
--
--   chart-colours:
--     - name: brand-blue
--       hex: "1B4F72"
--     - name: brand-orange
--       hex: "E67E22"

-- Default colour palette when meta colours run out
local default_palette = {
  "4E79A7", "F28E2B", "E15759", "76B7B2",
  "59A14F", "EDC948", "B07AA1", "FF9DA7",
  "9C755F", "BAB0AC"
}

-- ---------------------------------------------------------------
-- Parse chart-colours from document metadata
-- ---------------------------------------------------------------
local meta_colours = {}

function read_meta(meta)
  if meta["chart-colours"] then
    for _, item in ipairs(meta["chart-colours"]) do
      local name = pandoc.utils.stringify(item.name)
      local hex  = pandoc.utils.stringify(item.hex)
      meta_colours[name] = hex
    end
  end
end

-- ---------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------

local function trim(s)
  return s:match("^%s*(.-)%s*$")
end

-- Sanitise a label string for use in pgf-pie / pgfplots
-- Wraps in \mbox{} to prevent PGF math parsing, and escapes
-- LaTeX special characters
local function sanitise_label(s)
  -- Strip any user-supplied backslash escapes like \( \)
  s = s:gsub("\\%(", "(")
  s = s:gsub("\\%)", ")")

  -- Escape LaTeX special characters
  s = s:gsub("&", "\\&")
  s = s:gsub("%%", "\\%%")
  s = s:gsub("#", "\\#")
  s = s:gsub("_", "\\_")

  -- Escape $ for LaTeX (currency, not math mode)
  s = s:gsub("%$", "\\$")

  -- For pgf-pie: commas in labels break the delimiter
  -- Replace with semicolons
  s = s:gsub(",", ";")

  -- Wrap in \mbox{} to protect from PGF math parser
  return "\\mbox{" .. s .. "}"
end

-- Sanitise a caption string for LaTeX
local function sanitise_caption(s)
  -- Strip user-supplied backslash escapes
  s = s:gsub("\\%(", "(")
  s = s:gsub("\\%)", ")")

  -- Escape $ for LaTeX
  s = s:gsub("%$", "\\$")

  -- Escape other LaTeX specials (but not \ itself, user may want commands)
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
-- Canonical values: "full", "medium", "margin"
local function resolve_style(opts)
  local raw = (opts["style"] or opts["size"] or "full"):lower()
  -- Accept aliases
  if raw == "flow" or raw == "flow-mini" then
    return "medium"
  end
  if raw == "medium" or raw == "margin" then
    return raw
  end
  return "full"
end

local function parse_block(text)
  -- Returns: opts table, entries list of {label, value}
  local opts = {}
  local entries = {}

  for line in text:gmatch("[^\r\n]+") do
    line = trim(line)
    if line ~= "" then
      local key, val = line:match("^(%a[%a%-]*):%s*(.+)$")
      if key and not tonumber(val) then
        -- option line (key is purely alpha/hyphens, val is not a bare number)
        opts[key:lower()] = trim(val)
      else
        -- data line: "Some Label: 42" or "Some Label: 42.5"
        local label, num = line:match("^(.-):%s*([%d%.]+)%s*$")
        if label and num then
          table.insert(entries, { label = trim(label), value = tonumber(num) })
        end
      end
    end
  end

  return opts, entries
end

local function resolve_colours(opts, count)
  -- Build ordered list of hex colours for chart segments
  local colours = {}
  local named = {}

  if opts["colours"] then
    for name in opts["colours"]:gmatch("[^,]+") do
      table.insert(named, trim(name))
    end
  end

  for i = 1, count do
    if named[i] and meta_colours[named[i]] then
      colours[i] = meta_colours[named[i]]
    elseif named[i] and named[i]:match("^%x%x%x%x%x%x$") then
      -- raw hex passed directly
      colours[i] = named[i]
    else
      -- fall back to default palette (cycling)
      local idx = ((i - 1) % #default_palette) + 1
      colours[i] = default_palette[idx]
    end
  end

  return colours
end

local function colour_definitions(colours)
  -- Generate \definecolor lines
  local lines = {}
  for i, hex in ipairs(colours) do
    table.insert(lines, string.format(
      "\\definecolor{chartcol%d}{HTML}{%s}", i, hex
    ))
  end
  return table.concat(lines, "\n")
end

-- ---------------------------------------------------------------
-- Layout: figure_wrap
-- ---------------------------------------------------------------

-- Estimate chart height in cm for Needspace calculation
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

local function figure_wrap(content, opts, chart_type, entry_count)
  -- Wrap chart with Needspace-guarded positioning
  -- Three styles:
  --   full:   left-aligned inline, full text width
  --   medium: centred minipage, 55% text width
  --   margin: marginnote with checkoddpage, scaled to marginpar width
  local style = resolve_style(opts)
  local caption = opts["caption"]
  if caption then
    caption = sanitise_caption(caption)
  end
  local axis_dir = (opts["axis"] or "H"):upper()
  local needspace = estimate_chart_height(chart_type, entry_count, axis_dir, style)
  local lines = {}

  if style == "margin" then
    -- Margin placement following boxes.lua marginbox pattern
    -- Constrain to marginpar width with resizebox to prevent bleed overflow
    table.insert(lines, string.format("\\Needspace{%.1fcm}", needspace))
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
    -- Centred minipage: no float mechanics, no page-break issues
    -- Content constrained to minipage width via resizebox
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
    -- Full width: left-aligned inline, no float
    -- Content constrained to text width via resizebox
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

local function format_value(val, opts)
  local prefix  = opts["prefix"]  or ""
  local postfix = opts["postfix"] or ""
  local str
  if val == math.floor(val) then
    str = tostring(math.floor(val))
  else
    str = tostring(val)
  end
  return prefix .. str .. postfix
end

-- ---------------------------------------------------------------
-- Pie chart generator
-- ---------------------------------------------------------------

local function make_pie(opts, entries)
  local colours = resolve_colours(opts, #entries)
  local style = resolve_style(opts)
  local lines = {}

  table.insert(lines, colour_definitions(colours))
  table.insert(lines, "")

  -- Build pie data
  local pie_items = {}
  local colour_list = {}
  for i, e in ipairs(entries) do
    if style == "margin" then
      -- No labels for margin charts
      table.insert(pie_items, string.format("%s/", e.value))
    else
      table.insert(pie_items, string.format(
        "%s/%s", e.value, sanitise_label(e.label)
      ))
    end
    table.insert(colour_list, string.format("chartcol%d", i))
  end

  -- Build prefix/postfix for before/after number
  local before = sanitise_affix(opts["prefix"]  or "")
  local after  = sanitise_affix(opts["postfix"] or "")

  -- Scale and radius based on style
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

  -- Text display mode: legend for full/medium, inside for margin
  local text_opt
  if style == "margin" then
    text_opt = "inside"
  else
    text_opt = "legend"
  end

  table.insert(lines, string.format("\\begin{tikzpicture}[scale=%s]", scale))
  table.insert(lines, string.format(
    "\\pie[color={%s}, before number={%s}, after number={%s}, text=%s, radius=%s]{",
    table.concat(colour_list, ", "), before, after, text_opt, radius
  ))
  table.insert(lines, "  " .. table.concat(pie_items, ",\n  "))
  table.insert(lines, "}")
  table.insert(lines, "\\end{tikzpicture}")

  local chart = table.concat(lines, "\n")
  return figure_wrap(chart, opts, "pie", #entries)
end

-- ---------------------------------------------------------------
-- Bar chart generator
-- ---------------------------------------------------------------

local function make_bar(opts, entries)
  local colours = resolve_colours(opts, #entries)
  local axis_dir = (opts["axis"] or "H"):upper()
  local style = resolve_style(opts)
  local lines = {}

  table.insert(lines, colour_definitions(colours))
  table.insert(lines, "")

  local scale = (style == "medium") and "0.8" or "1.0"
  local prefix  = sanitise_affix(opts["prefix"]  or "")
  local postfix = sanitise_affix(opts["postfix"] or "")

  -- Build coordinate list and labels (sanitised for pgfplots symbolic coords)
  local labels = {}
  for _, e in ipairs(entries) do
    table.insert(labels, sanitise_label(e.label))
  end

  -- Find max value for axis headroom (labels need space beyond bar tip)
  local max_val = 0
  for _, e in ipairs(entries) do
    if e.value > max_val then max_val = e.value end
  end
  local headroom = math.ceil(max_val * 1.25)

  -- Height scales with entry count for horizontal
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

  -- Nodes near coords with prefix/postfix
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

  -- One addplot per bar (necessary for per-bar colour from cycle list)
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

  local chart = table.concat(lines, "\n")
  return figure_wrap(chart, opts, "bar", #entries)
end

-- ---------------------------------------------------------------
-- CodeBlock filter
-- ---------------------------------------------------------------

function CodeBlock(el)
  local chart_type = nil

  if el.classes[1] == "piechart" then
    chart_type = "pie"
  elseif el.classes[1] == "barchart" then
    chart_type = "bar"
  end

  if not chart_type then
    return nil
  end

  local opts, entries = parse_block(el.text)

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

-- ---------------------------------------------------------------
-- Filter sequence: read meta first, then process code blocks
-- ---------------------------------------------------------------

return {
  { Meta = read_meta },
  { CodeBlock = CodeBlock }
}
