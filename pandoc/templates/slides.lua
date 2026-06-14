-- slides.lua - transform a Markdown document into modern full-bleed PDF slides
-- for the `slides` template (xelatex, not beamer).
--
-- Slide model (mirrors beamer's default slide level):
--   #  (H1)  -> a section / divider slide (big centred title on the title ground)
--   ## (H2)  -> a content slide (title + the blocks beneath it)
--   front matter title/subtitle -> the opening title slide (drawn by the template)
--
-- Per-slide colour role from the H2's attributes: {.light} (default), {.dark},
-- {.accent}.  Standalone images are wrapped in a white card unless marked
-- {.plain}.  `::: columns` / `:::: column` become side-by-side minipages.

local stringify = pandoc.utils.stringify

-- Escape the LaTeX specials that can appear in a heading title.
local function esc(s)
  return (s:gsub('[\\{}$&#%%_^~]', {
    ['\\']='\\textbackslash{}', ['{']='\\{', ['}']='\\}', ['$']='\\$',
    ['&']='\\&', ['#']='\\#', ['%']='\\%', ['_']='\\_',
    ['^']='\\textasciicircum{}', ['~']='\\textasciitilde{}' }))
end

-- An image -> \includegraphics with width honoured, carded unless .plain.
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

-- Standalone image paragraph -> centred (carded) image block.
function Para(p)
  if #p.content == 1 and p.content[1].t == 'Image' then
    return pandoc.RawBlock('latex', '\\begin{center}'..image_latex(p.content[1])..'\\end{center}')
  end
end

-- ::: columns / :::: column -> side-by-side minipages.
function Div(div)
  if div.classes:includes('columns') then
    local cols = {}
    for _, c in ipairs(div.content) do
      if c.t == 'Div' and c.classes:includes('column') then cols[#cols+1] = c end
    end
    if #cols == 0 then return nil end
    local w = string.format('%.3f', 0.94 / #cols)
    local out = {}
    for i, c in ipairs(cols) do
      local body = pandoc.write(pandoc.Pandoc(c.content), 'latex')
      out[#out+1] = '\\begin{minipage}[t]{'..w..'\\linewidth}'..body..'\\end{minipage}'
      if i < #cols then out[#out+1] = '\\hfill' end
    end
    return pandoc.RawBlock('latex', '\\par\\medskip\\noindent ' .. table.concat(out, '%\n'))
  end
end

-- Role keyword from an H2's classes.
local function role_of(h)
  for _, r in ipairs({'dark', 'accent', 'light'}) do
    if h.classes:includes(r) then return r end
  end
  return 'light'
end

-- Regroup the document into slides.
function Pandoc(doc)
  local out = pandoc.List()
  local open = false
  local function close() if open then out:insert(pandoc.RawBlock('latex', '\\EndSlide')) ; open = false end end
  for _, blk in ipairs(doc.blocks) do
    if blk.t == 'Header' and blk.level == 1 then
      close()
      out:insert(pandoc.RawBlock('latex', '\\SectionSlide{'..esc(stringify(blk.content))..'}'))
    elseif blk.t == 'Header' and blk.level == 2 then
      close()
      out:insert(pandoc.RawBlock('latex',
        '\\BeginSlide['..role_of(blk)..']{'..esc(stringify(blk.content))..'}'))
      open = true
    else
      out:insert(blk)
    end
  end
  close()
  doc.blocks = out
  return doc
end
