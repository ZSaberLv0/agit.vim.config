
" default align logic is very slow on large repo, replace it
function! agit#aligner#align(table, max_col, ...)
    let ret = []
    for items in a:table
        let line = ''
        for item in items
            if empty(line)
                let line = item
                if len(line) < 120
                    let line .= repeat(' ', 120 - len(line))
                else
                    let line .= '    '
                endif
            else
                let line .= '  ' . item
            endif
        endfor
        call add(ret, substitute(line, '[ \t]\+$', '', ''))
    endfor
    return ret
endfunction

