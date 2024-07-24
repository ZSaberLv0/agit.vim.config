
function! agit#git#exec(command, git_root, ...)
    let command = a:command
    if match(command, '--date') >= 0
        " --date=[a-zA-Z0-9]+
        let command = substitute(command, '--date=[a-zA-Z0-9]\+', ' --date=format:"%Y-%m-%d %H:%M:%S" ', '')
    elseif match(command, '\<show\>') >= 0
        let command .= ' --date=format:"%Y-%m-%d %H:%M:%S" '
    endif

    let cmd = 'cd "' . a:git_root . '" && ' . 'git --no-pager ' . command
    if a:0 > 0 && a:1 == 1
        execute '!' . cmd
    else
        return system(cmd)
    endif
endfunction

