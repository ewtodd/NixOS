{ ... }: {
  programs.nixvim.extraConfigLua = ''
    local ls = require("luasnip")
    local s = ls.snippet
    local t = ls.text_node
    local i = ls.insert_node
    local d = ls.dynamic_node
    local r = ls.restore_node
    local sn = ls.snippet_node
    local fmt = require("luasnip.extras.fmt").fmt
    local rep = require("luasnip.extras").rep

    -- Function to count columns from tabular description
    local function column_count_from_string(descr)
        -- Count c, l, r, m, p, b, X characters (common column types)
        local count = 0
        for char in descr:gmatch("[clrmpbX]") do
            count = count + 1
        end
        return count
    end

    -- Dynamic table function
    local tab = function(args, snip)
        local cols = column_count_from_string(args[1][1])
        if cols == 0 then cols = 2 end -- Default to 2 columns if none detected
        
        local nodes = {}
        local ins_indx = 1
        
        -- Create first row
        table.insert(nodes, i(ins_indx))
        ins_indx = ins_indx + 1
        
        for k = 2, cols do
            table.insert(nodes, t" & ")
            table.insert(nodes, i(ins_indx))
            ins_indx = ins_indx + 1
        end
        table.insert(nodes, t{" \\\\", ""})
        
        return sn(nil, nodes)
    end

    -- LaTeX snippets
    ls.add_snippets("tex", {
        -- Dynamic table snippet
        s("tab", fmt([[
    \begin{{tabular}}{{{}}}
    {}
    \end{{tabular}}
    ]], {i(1, "c|c"), d(2, tab, {1})})),

        -- Simple table templates
        s("table2", fmt([[
    \begin{{tabular}}{{|c|c|}}
    \hline
    {} & {} \\
    \hline
    {} & {} \\
    \hline
    \end{{tabular}}
    ]], {i(1), i(2), i(3), i(4)})),

        s("table3", fmt([[
    \begin{{tabular}}{{|c|c|c|}}
    \hline
    {} & {} & {} \\
    \hline
    {} & {} & {} \\
    \hline
    {} & {} & {} \\
    \hline
    \end{{tabular}}
    ]], {i(1), i(2), i(3), i(4), i(5), i(6), i(7), i(8), i(9)})),

        -- Figure snippets
        s("fig", fmt([[
    \begin{{figure}}[{}]
        \centering
        \includegraphics[width={}]{{{}}}
        \caption{{{}}}
        \label{{fig:{}}}
    \end{{figure}}
    ]], {i(1, "htb!"), i(2, "0.8\\textwidth"), i(3, "image.png"), i(4, "Caption"), i(5, "label")})),

        s("subfig", fmt([[
    \begin{{figure}}[{}]
        \centering
        \begin{{subfigure}}[b]{{{}}}
            \centering
            \includegraphics[width=\textwidth]{{{}}}
            \caption{{{}}}
            \label{{fig:{}}}
        \end{{subfigure}}
        \hfill
        \begin{{subfigure}}[b]{{{}}}
            \centering
            \includegraphics[width=\textwidth]{{{}}}
            \caption{{{}}}
            \label{{fig:{}}}
        \end{{subfigure}}
        \caption{{{}}}
        \label{{fig:{}}}
    \end{{figure}}
    ]], {
        i(1, "htbp"), i(2, "0.45\\textwidth"), i(3, "image1.png"), i(4, "Caption 1"), i(5, "label1"),
        i(6, "0.45\\textwidth"), i(7, "image2.png"), i(8, "Caption 2"), i(9, "label2"),
        i(10, "Main caption"), i(11, "main-label")
    })),

        -- Wrap figure (for text wrapping around figures)
        s("wrapfig", fmt([[
    \begin{{wrapfigure}}{{{}}}{{{}}}
        \centering
        \includegraphics[width={}]{{{}}}
        \caption{{{}}}
        \label{{fig:{}}}
    \end{{wrapfigure}}
    ]], {i(1, "r"), i(2, "0.5\\textwidth"), i(3, "0.48\\textwidth"), i(4, "image.png"), i(5, "Caption"), i(6, "label")})),

        -- TikZ figure
        s("tikz", fmt([[
    \begin{{figure}}[{}]
        \centering
        \begin{{tikzpicture}}
            {}
        \end{{tikzpicture}}
        \caption{{{}}}
        \label{{fig:{}}}
    \end{{figure}}
    ]], {i(1, "htbp"), i(2, "% TikZ code here"), i(3, "Caption"), i(4, "label")})),

        -- Equation snippets
        s("eq", fmt([[
    \begin{{equation}}
        {}
        \label{{eq:{}}}
    \end{{equation}}
    ]], {i(1, "E = mc^2"), i(2, "label")})),

        s("align", fmt([[
    \begin{{align}}
        {} &= {} \\
        &= {}
        \label{{eq:{}}}
    \end{{align}}
    ]], {i(1, "x"), i(2, "y + z"), i(3, "result"), i(4, "label")})),

        -- List snippets
        s("itemize", fmt([[
    \begin{{itemize}}
        \item {}
        \item {}
    \end{{itemize}}
    ]], {i(1, "First item"), i(2, "Second item")})),

        s("enumerate", fmt([[
    \begin{{enumerate}}
        \item {}
        \item {}
    \end{{enumerate}}
    ]], {i(1, "First item"), i(2, "Second item")})),

        -- Section snippets
        s("sec", fmt([[\section{{{}}}]], {i(1, "Section Title")})),
        s("subsec", fmt([[\subsection{{{}}}]], {i(1, "Subsection Title")})),
        s("subsubsec", fmt([[\subsubsection{{{}}}]], {i(1, "Subsubsection Title")})),

        -- Reference snippets
        s("ref", fmt([[\ref{{{}}}]], {i(1, "label")})),
        s("eqref", fmt([[\eqref{{{}}}]], {i(1, "eq:label")})),
        s("figref", fmt([[\ref{{fig:{}}}]], {i(1, "label")})),
        s("tabref", fmt([[\ref{{tab:{}}}]], {i(1, "label")})),

        -- Math snippets
        s("frac", fmt([[\frac{{{}}}{{{}}}]], {i(1, "numerator"), i(2, "denominator")})),
        s("sqrt", fmt([[\sqrt{{{}}}]], {i(1, "expression")})),
        s("sum", fmt([[\sum_{{{}}}^{{{}}} {}]], {i(1, "i=1"), i(2, "n"), i(3, "expression")})),
        s("int", fmt([[\int_{{{}}}^{{{}}} {} \, d{}]], {i(1, "a"), i(2, "b"), i(3, "f(x)"), i(4, "x")})),

        -- Document structure
        s("doc", fmt([[
    \documentclass[{}]{{{}}}

    \usepackage{{amsmath}}
    \usepackage{{graphicx}}
    \usepackage{{subcaption}}
    \usepackage{{wrapfig}}
    \usepackage{{tikz}}

    \title{{{}}}
    \author{{{}}}
    \date{{{}}}

    \begin{{document}}

    \maketitle

    {}

    \end{{document}}
    ]], {i(1, "12pt"), i(2, "article"), i(3, "Document Title"), i(4, "Author Name"), i(5, "\\today"), i(6, "Content")})),
    })
  '';
}
