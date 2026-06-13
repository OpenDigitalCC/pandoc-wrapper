-- boxes.lua

function Div(el)

    -- Compute vertical space based on character count per line.
    local text = pandoc.utils.stringify(el)
    local charCount = 0
    local charsPerLine = 0
    recommendationCounter = recommendationCounter or 0
    for char in string.gmatch(text, ".") do
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
    end
    local charLines = math.ceil(charCount / charsPerLine)
    local lineHeight = 0.7  -- in cm
    local headingSpace = 2.0  -- Extra space for heading above box (in cm)
    local needspace_cm = (charLines * lineHeight) + headingSpace
--    io.stderr:write(" LUA: Computed needspace_cm for textbox = " .. tostring(needspace_cm) .. "\n")
    local doc = pandoc.Pandoc(el.content)
    local full_content = pandoc.write(doc, "latex")
    local content = full_content:match("\\begin{document}(.*)\\end{document}")
    if not content then
      content = full_content
    end
    content = content:gsub("^%s+", ""):gsub("%s+$", "")

  -- Process Div with class "textbox": a wrapped text box covering 60% of the page.
  if el.classes:includes("textbox") then

    local latex = [[
\Needspace{]] .. needspace_cm .. [[cm}
\setlength{\intextsep}{3pt}
\begin{wrapfigure}{r}{0.6\textwidth}%
  \hspace*{-1cm}%
  \begin{tcolorbox}[
  colframe=ForestGreen!90, 
  colback=SlateBlue!10, 
  boxrule=2pt, 
  arc=2mm, 
  auto outer arc, 
  left=3mm, 
  right=3mm, 
  width=\linewidth
]
\setlength{\parskip}{1.0em}
\faInfoCircle\hspace{0.5em}
]] .. content .. [[
  \end{tcolorbox}
\end{wrapfigure}
]]
    return pandoc.RawBlock("latex", latex)

  -- Process recommendation boxes

  elseif el.classes:includes("recommendation") then
  
  recommendationCounter = recommendationCounter + 1
  local anchor = "recommendation-" .. tostring(recommendationCounter)
  local counterStr = tostring(recommendationCounter)
  
    local latex = [[
\Needspace{]] .. needspace_cm .. [[cm}
\begin{tcolorbox}[
  colframe=DeepPurple!90, 
  colback=TealBlue!10,
  boxrule=0pt,
  leftrule=2pt,
  sharp corners,
  left=3mm, 
  right=3mm, 
  width=\linewidth,
]
  \hypertarget{]] .. anchor .. [[}{}
  {\bfseries\setlength{\parskip}{1.0em} Recommendation ]] .. counterStr .. [[: }\par{ 
  
]] .. content .. [[

}
  \end{tcolorbox}
]]
    return pandoc.RawBlock("latex", latex)


  -- Process example boxes

  elseif el.classes:includes("examplebox") then
    local latex = [[
\Needspace{]] .. needspace_cm .. [[cm}
\begin{tcolorbox}[
  colframe=DeepPurple!90, 
  colback=SoftCyan!10,
  boxrule=0pt,
  leftrule=2pt,
  sharp corners,
  left=3mm, 
  right=3mm, 
  width=\linewidth,
]
\faBookOpen\hspace{0.5em}
]] .. content .. [[
  \end{tcolorbox}
]]
    return pandoc.RawBlock("latex", latex)

  -- Process policy summary boxes

  elseif el.classes:includes("box-policysummary") then
    local latex = [[
\Needspace{]] .. needspace_cm .. [[cm}
\begin{tcolorbox}[
  colframe=DeepPurple!90, 
  colback=DeepRust!10,
  boxrule=0pt,
  leftrule=2pt,
  sharp corners,
  left=3mm, 
  right=3mm, 
  width=\linewidth,
]
{\bfseries\setlength{\parskip}{1.0em}\faBalanceScale\hspace{0.5em} Policy concept summary }\par{ 
  ]] .. content .. [[
  }
  \end{tcolorbox}
]]
    return pandoc.RawBlock("latex", latex)


  -- Process budget boxes

  elseif el.classes:includes("budgetbox") then
    local latex = [[
\Needspace{]] .. needspace_cm .. [[cm}
\begin{tcolorbox}[
  colframe=DeepRust!90, 
  colback=ForestGreen!20,
  boxrule=0pt,
  leftrule=2pt,
  sharp corners,
  left=3mm, 
  right=3mm, 
  width=\linewidth,
]
{\bfseries\setlength{\parskip}{1.0em}\faEuroSign\hspace{0.5em} Budgetary proposal }\par{ 
  ]] .. content .. [[
  }
  \end{tcolorbox}
]]
    return pandoc.RawBlock("latex", latex)



  -- Process Div with class "widebox": a horizontal box spanning the text width.
  elseif el.classes:includes("widebox") then
--    io.stderr:write(" LUA: Found widebox\n")
    local latex = [[
\Needspace{]] .. needspace_cm .. [[cm}
\begin{tcolorbox}[
  colframe=SoftCyan!90,
  colback=TealBlue!10,
  boxrule=2pt, 
  arc=2mm,
  auto outer arc,
  left=3mm, 
  right=3mm, 
  width=\linewidth
]
{\setlength{\parskip}{1.0em}
]] .. content .. [[ }
\end{tcolorbox}
]]
    return pandoc.RawBlock("latex", latex)

  -- Process Div with class "marginbox": place a box in the page margin using \marginpar.
  elseif el.classes:includes("marginbox") then
--    io.stderr:write(" LUA: Found marginbox\n")
    local latex = 
[[
\Needspace{]] .. needspace_cm .. [[cm}
  \checkoddpage
  \ifoddpage
  \marginnote{
    \begin{tcolorbox}[
      colframe=DeepRust!90, 
      boxrule=0pt,
      leftrule=2pt,
      sharp corners,
      left=1mm, 
      right=1mm, 
    ]
    \raggedright\setlength{\parskip}{1.0em} 
    ]] .. content .. [[
    \end{tcolorbox}
  }
  \else
    \marginnote{
    \begin{tcolorbox}[
      colframe=DeepRust!90, 
      boxrule=0pt,
      rightrule=2pt,
      sharp corners,
      left=1mm, 
      right=1mm, 
    ]
    \raggedleft\setlength{\parskip}{1.0em} 
    ]] .. content .. [[
    \end{tcolorbox}
  }
  \fi
]]
    return pandoc.RawBlock("latex", latex)
  end

-- End of Div processing function

end

