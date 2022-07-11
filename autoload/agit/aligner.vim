
" align is very slow on large repo, disable it
function! agit#aligner#align(table, max_col, ...)
    let ret = []
    for item in a:table
        call add(ret, substitute(join(item, "\t\t"), '[ \t]\+$', '', ''))
    endfor
    return ret
endfunction

