
function! agit#git#exec(command, git_root, ...)
    let cmd = 'cd "' . a:git_root . '" && ' . 'git --no-pager ' . a:command
    if a:0 > 0 && a:1 == 1
        execute '!' . cmd
    else
        return system(cmd)
    endif
endfunction

