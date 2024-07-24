
" default align logic is very slow on large repo, replace it
function! agit#aligner#align(table, max_col, ...)
    let align = &columns - 60
    if align < 80
        let align = 80
    endif

    let ret = []
    for items in a:table
        let line = items[0]
        let lineWidth = strdisplaywidth(line)
        if lineWidth < align
            let line .= repeat(' ', align - lineWidth)
        else
            let line .= ' '
        endif
        let i = 1
        let iEnd = len(items)
        while i < iEnd
            let line .= ' '
            let line .= items[i]
            let i += 1
        endwhile
        call add(ret, substitute(line, '[ \t]\+$', '', ''))
    endfor
    return ret
endfunction

