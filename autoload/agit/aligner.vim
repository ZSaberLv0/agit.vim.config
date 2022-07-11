
" default align logic is very slow on large repo, replace it
function! agit#aligner#align(table, max_col, ...)
    let align = &columns - 30

    let ret = []
    for items in a:table
        let line = ''
        for item in items
            if empty(line)
                let line = item
                if len(line) < align
                    let line .= repeat(' ', align - len(line))
                else
                    let line .= '  '
                endif
            else
                let line .= item
                let line .= '  '
            endif
        endfor
        call add(ret, substitute(line, '[ \t]\+$', '', ''))
    endfor
    return ret
endfunction

