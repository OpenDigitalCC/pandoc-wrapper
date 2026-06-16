-- slides.lua - transform a Markdown document into modern full-bleed PDF slides
-- for the `slides` template (xelatex, not beamer).
--
-- Slide model:
--   #  (H1)  -> a section / divider slide (big centred title on the title ground)
--   ## (H2)  -> a content slide. Attributes on the H2:
--                {.light|.dark|.accent}      colour role (default light)
--                label="Running Header"      shown top-right in the brand bar
--                accent="Second line"        a second, accent-coloured headline line
--   front-matter title/subtitle -> the opening title slide (template-drawn)
--
-- Component divs (slide-tuned here; the macro names are the cross-template
-- contract): ::: stats / ::: stat, ::: cards / ::: card, ::: people / ::: person,
-- ::: steps (an ordered list), ::: tiers / ::: tier, ::: milestones / ::: milestone,
-- ::: callout, ::: takeaway, ::: actions (links). Inline [text]{.pill} -> a chip.
-- `::: columns` / `:::: column` remain side-by-side minipages; a column may carry
-- a .card / .fill / .dark role to become a panel.

local stringify = pandoc.utils.stringify

local function esc(s)
  return (s:gsub('[\\{}$&#%%_^~]', {
    ['\\']='\\textbackslash{}', ['{']='\\{', ['}']='\\}', ['$']='\\$',
    ['&']='\\&', ['#']='\\#', ['%']='\\%', ['_']='\\_',
    ['^']='\\textasciicircum{}', ['~']='\\textasciitilde{}' }))
end

-- Render a list of blocks to a LaTeX string (preserves bold/lists/etc.).
local function render(blocks)
  return pandoc.write(pandoc.Pandoc(blocks), 'latex')
end

local function raw(s) return pandoc.RawBlock('latex', s) end

-- Pull a leading heading off a list of blocks: returns (title_string, rest).
local function take_heading(blocks)
  if blocks[1] and blocks[1].t == 'Header' then
    local t = stringify(blocks[1].content)
    local rest = {}
    for i = 2, #blocks do rest[#rest+1] = blocks[i] end
    return t, rest
  end
  return nil, blocks
end

-- Children of a container div that carry a given class.
local function children(div, class)
  local out = {}
  for _, c in ipairs(div.content) do
    if c.t == 'Div' and (class == nil or c.classes:includes(class)) then out[#out+1] = c end
  end
  return out
end

-- An image -> \includegraphics, carded unless .plain.
local function image_latex(img)
  local opt = 'height=0.6\\slideh,width=\\linewidth,keepaspectratio'
  local w = img.attributes.width
  if w then
    local pct = w:match('^(%d+)%%$')
    if pct then opt = 'width='..(tonumber(pct)/100)..'\\linewidth,keepaspectratio'
    else opt = 'width='..w..',keepaspectratio' end
  end
  local g = '\\includegraphics['..opt..']{'..img.src..'}'
  if img.classes:includes('plain') then return g else return '\\slidecard{'..g..'}' end
end

function Para(p)
  if #p.content == 1 and p.content[1].t == 'Image' then
    return raw('\\begin{center}'..image_latex(p.content[1])..'\\end{center}')
  end
end

-- Inline pill: [text]{.pill}
function Span(s)
  if s.classes:includes('pill') then
    return pandoc.RawInline('latex', '\\pill{'..esc(stringify(s.content))..'}')
  end
end

-- ------- component builders ----------------------------------------------
local function card_role(div)
  for _, r in ipairs({'dark', 'fill', 'white'}) do
    if div.classes:includes(r) then return r end
  end
  return nil
end

-- A row of cards as a tcbitemize (equal-height boxes via \tcbitem, single pass).
-- `cols` boxes per row; items beyond that wrap to further rows.
local function raster(cols, items)
  if #items == 0 then return '' end
  return '\\par\\medskip\\begin{tcbitemize}[slraster, raster columns='..cols..']'
    .. table.concat(items) .. '\\end{tcbitemize}\\par\\medskip'
end

local CARD_ITEM = { white = '\\carditemw', fill = '\\carditemf', dark = '\\carditemd' }

local function build_stats(div)
  local items = {}
  for _, st in ipairs(children(div, 'stat')) do
    local b = st.content
    local figure = b[1] and stringify(b[1]) or ''
    local label  = b[2] and stringify(b[2]) or ''
    local note   = ''
    for i = 3, #b do note = note .. (note ~= '' and ' ' or '') .. stringify(b[i]) end
    local col = st.attributes.color or 'saccent'
    items[#items+1] = '\\statitem['..col..']{'..esc(figure)..'}{'..esc(label)..'}{'..esc(note)..'}'
  end
  return raw(raster(math.min(#items, 3), items))
end

local function build_cards(div, kind)
  local items = {}
  for _, c in ipairs(children(div, kind == 'people' and 'person' or 'card')) do
    if kind == 'people' then
      local name, rest = take_heading(c.content)
      local role = rest[1] and stringify(rest[1]) or ''
      local bio = {}
      for i = 2, #rest do bio[#bio+1] = rest[i] end
      items[#items+1] = '\\personitem{'..esc(name or '')..'}{'..esc(role)..'}{'..render(bio)..'}'
    else
      local m = CARD_ITEM[card_role(c) or 'white']
      local title, rest = take_heading(c.content)
      items[#items+1] = m..'{'..esc(title or '')..'}{'..render(rest)..'}'
    end
  end
  return raw(raster(math.min(#items, 3), items))
end

local function build_tiers(div)
  local items = {}
  for _, t in ipairs(children(div, 'tier')) do
    local b = t.content
    local figure = b[1] and stringify(b[1]) or ''
    local label  = b[2] and stringify(b[2]) or ''
    local body = {}
    for i = 3, #b do body[#body+1] = b[i] end
    local col = t.attributes.color or 'saccent'
    items[#items+1] = '\\tieritem{'..col..'}{'..esc(t.attributes.stage or '')..'}{'
      ..esc(figure)..'}{'..esc(label)..'}{'..render(body)..'}'
  end
  return raw(raster(math.min(#items, 3), items))
end

local function build_milestones(div)
  local items = {}
  local n = 0
  for _, m in ipairs(children(div, 'milestone')) do
    n = n + 1
    local title, rest = take_heading(m.content)
    items[#items+1] = '\\mileitem{'..string.format('%02d', n)..'}{'..esc(title or '')
      ..'}{'..esc(m.attributes.date or '')..'}{'..render(rest)..'}'
  end
  return raw(raster(math.min(#items, 3), items))
end

-- ::: steps wraps an ordered list; each item -> a numbered badge row.
local function build_steps(div)
  local out = {}
  for _, blk in ipairs(div.content) do
    if blk.t == 'OrderedList' then
      local n = 0
      for _, item in ipairs(blk.content) do
        n = n + 1
        -- the item's first block (a bold para or a heading) is the step heading
        local title = item[1] and stringify(item[1]) or ''
        local rest = {}
        for i = 2, #item do rest[#rest+1] = item[i] end
        out[#out+1] = '\\steprow{'..n..'}{'..esc(title)..'}{'..render(rest)..'}'
      end
    end
  end
  return raw(table.concat(out))
end

local function build_columns(div)
  local cols = children(div, 'column')
  if #cols == 0 then return nil end
  -- If every column carries a card role, lay them out as an equal-height panel
  -- raster (the two-panel compare). Otherwise plain side-by-side minipages.
  local all_card = true
  for _, c in ipairs(cols) do if not card_role(c) then all_card = false break end end
  if all_card then
    local items = {}
    for _, c in ipairs(cols) do
      local title, rest = take_heading(c.content)
      items[#items+1] = CARD_ITEM[card_role(c)]..'{'..esc(title or '')..'}{'..render(rest)..'}'
    end
    return raw(raster(#cols, items))
  end
  local w = string.format('%.3f', 0.97 / #cols)
  local out = {}
  for i, c in ipairs(cols) do
    out[#out+1] = '\\begin{minipage}[t]{'..w..'\\linewidth}'..render(c.content)..'\\end{minipage}'
    if i < #cols then out[#out+1] = '\\hfill' end
  end
  return raw('\\par\\medskip\\noindent '..table.concat(out, '%\n'))
end

local function build_actions(div)
  local btns = {}
  pandoc.walk_block(div, { Link = function(l)
    local txt = esc(stringify(l.content))
    local url = esc(l.target)
    btns[#btns+1] = { txt = txt, url = url, light = l.classes:includes('light') }
  end })
  local out = {}
  for _, b in ipairs(btns) do
    local label = b.txt .. '\\;\\textrightarrow\\;' .. b.url
    if b.light then out[#out+1] = '\\slidebuttonlight{'..label..'}'
    else out[#out+1] = '\\slidebutton{dark}{'..label..'}' end
  end
  return raw('\\par\\medskip\\noindent '..table.concat(out, '\\hfill '))
end

function Div(div)
  if div.classes:includes('stats')      then return build_stats(div) end
  if div.classes:includes('cards')      then return build_cards(div, 'cards') end
  if div.classes:includes('people')     then return build_cards(div, 'people') end
  if div.classes:includes('tiers')      then return build_tiers(div) end
  if div.classes:includes('milestones') then return build_milestones(div) end
  if div.classes:includes('steps')      then return build_steps(div) end
  if div.classes:includes('columns')    then return build_columns(div) end
  if div.classes:includes('callout') then
    return { raw('\\begin{slidecallout}'), pandoc.Div(div.content), raw('\\end{slidecallout}') }
  end
  if div.classes:includes('takeaway') then
    return { raw('\\begin{slidetakeaway}'), pandoc.Div(div.content), raw('\\end{slidetakeaway}') }
  end
  if div.classes:includes('actions') then return build_actions(div) end
end

-- Role keyword from an H2's classes (.invert is an alias for .dark).
local function role_of(h)
  for _, r in ipairs({'dark', 'accent', 'light'}) do
    if h.classes:includes(r) then return r end
  end
  if h.classes:includes('invert') then return 'dark' end
  return 'light'
end

-- Regroup the document into slides. Body blocks within a slide are separated by
-- \vfill so they distribute down the full slide height (vertical justification)
-- rather than bunching under the headline.
function Pandoc(doc)
  local out = pandoc.List()
  local open = false
  local function close() if open then out:insert(raw('\\vfill\\EndSlide')); open = false end end
  for _, blk in ipairs(doc.blocks) do
    if blk.t == 'Header' and blk.level == 1 then
      close()
      out:insert(raw('\\SectionSlide{'..esc(stringify(blk.content))..'}'))
    elseif blk.t == 'Header' and blk.level == 2 then
      close()
      local title = esc(stringify(blk.content))
      local accent = blk.attributes.accent
      if accent and accent ~= '' then
        title = title .. '\\\\{\\color{\\headaccent}' .. esc(accent) .. '}'
      end
      local label = blk.attributes.label or ''
      out:insert(raw('\\BeginSlide['..role_of(blk)..']{'..title..'}{'..esc(label)..'}'))
      open = true
    else
      if open then out:insert(raw('\\vfill')) end
      out:insert(blk)
    end
  end
  close()
  doc.blocks = out
  return doc
end
