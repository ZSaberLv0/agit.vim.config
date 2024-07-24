
function! agit#git#exec(command, git_root, ...)
    let command = a:command
    if match(command, '--date') >= 0
        " --date=[a-zA-Z0-9]+
        let command = substitute(command, '--date=[a-zA-Z0-9]\+', ' --date=format:"%Y-%m-%d %H:%M:%S" ', '')
    elseif match(command, '\<show\>') >= 0
        let command .= ' --date=format:"%Y-%m-%d %H:%M:%S" '
    endif

    let cmd = 'cd "' . a:git_root . '" && ' . 'git --no-pager ' . command
    let ret = system(cmd)
    if exists('g:agit_cmd_log')
        call add(g:agit_cmd_log, [command, substitute(ret, '\n', '\\n', 'g')])
    endif
    return ret
endfunction

function! agit#git#exec_or_die(command, git_root)
  let ret = agit#git#exec(a:command, a:git_root)
  if v:shell_error == 0
    return ret
  else
    let command_name = matchstr(a:command, '^\S\+')
    let error = substitute(ret, '[\r\n].*', '', 'g')
    throw 'Agit: git ' . command_name . ' failed(' . string(v:shell_error) . '). ' . error
  endif
endfunction

