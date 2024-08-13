
let g:agit_no_default_mappings = 1
let g:agit_ignore_spaces = 0
let g:agit_log_width = 1024
let g:agit_stat_width = 1024

" ============================================================
let g:agit_max_log_lines = 99999999
let s:pluginPath = fnamemodify(expand('<sfile>'), ':p:h:h')
function! s:updateImpl()
    if get(s:, 'firsttime', 1)
        let s:firsttime = 0
        call agit#aligner#align([], 80)
        call agit#git#exec('status -s', getcwd())

        execute 'source ' . fnameescape(s:pluginPath . '/autoload/agit/aligner.vim')
        execute 'source ' . fnameescape(s:pluginPath . '/autoload/agit/git.vim')
    endif
endfunction
call s:updateImpl()
" ============================================================

" option: {
"   'confirm' : 1/0,
"   'message' : 'unable to parse rev, perform unshallow?',
" }
function! AGIT_unshallow(...)
    let option = get(a:, 1, {})
    if get(option, 'confirm', 1)
        redraw!
        echo get(option, 'message', 'unable to parse rev, perform unshallow?')
        echo '  (y)es'
        echo '  (n)o'
        echo 'choose: '
        let cmd = getchar()
        if cmd != char2nr('y')
            redraw! | echo 'canceled'
            return
        endif
    endif
    redraw! | echo 'unshallow running...'
    call system('git fetch --unshallow')
    call system('git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"')
    call system('git fetch origin')
    execute "normal \<Plug>(agit-reload)"
    redraw! | echo 'unshallow finished'
endfunction

function! AGIT_fixEndl()
    " when file is dos endl, the history file may have `^M`
    if &modifiable
        return
    endif
    setlocal modifiable
    silent! %s/\r//g
    setlocal nomodified
    setlocal nomodifiable
endfunction

function! AGIT_main(path)
    let g:loaded_fugitive = 0
    call s:updateImpl()
    if isdirectory(a:path)
        let path = substitute(a:path, '\\', '/', 'g')
        let path = substitute(path, ' ', '\\ ', 'g')
        execute 'cd ' . path
    endif
    call system('git config core.quotepath false')
    let path = getcwd()
    if match(path, ' ') >= 0
        Agit
    else
        " without `--file`, would result to default `%`,
        " which would cause `Agit: File not tracked:` if current opened file not tracked by git
        execute printf('Agit --dir=%s --file=%s', path, path)
    endif

    call AGIT_tmpStashCheck()
endfunction

function! AGIT_file(path) abort
    call s:updateImpl()
    let path = a:path
    if &filetype == 'agit_stat'
        let path = AGIT_stat_getCurFile()
        if empty(path)
            echo 'no file under cursor'
            return
        endif
    elseif &filetype == 'agit' || &filetype == 'agit_diff'
        echo 'not available for current window'
        return
    else
        if empty(path)
            let path = expand('%')
            if empty(path)
                echo 'no file opened'
                return
            endif
            " \([0-9a-f]{6}\)$
            let path = substitute(path, '([0-9a-f]\{6})$', '', '')
        endif
    endif
    if match(path, ' ') >= 0
        let path = substitute(path, '\\', '/', 'g')
        let path = substitute(path, ' ', '\\ ', 'g')
        execute 'edit ' . path
        AgitFile
    else
        execute 'AgitFile --file=' . path
    endif
    nnoremap <silent><buffer> o :call AGIT_file_open()<cr>
endfunction
function! AGIT_file_open()
    let tabCount = tabpagenr('$')
    let diffResult = ''
    execute "normal \<Plug>(agit-diff)"
    if tabpagenr('$') <= tabCount
        call AGIT_unshallow()
        return
    endif

    execute "normal! \<c-w>h"
    nnoremap <buffer><silent> q :call AGIT_diffBuf_quit()<cr>
    call AGIT_fixEndl()
    execute "normal! \<c-w>l"
    nnoremap <buffer><silent> q :call AGIT_diffBuf_quit()<cr>
    call AGIT_fixEndl()
    normal! ]czz
endfunction

function! AGIT_diffBuf_askWrite()
    if !&modified
        return 0
    endif
    let input = confirm("File " . expand("%:p") . " modified, save?", "&Yes\n&No", 1)
    redraw
    if input == 1
        w!
        return 1
    else
        return 0
    endif
endfunction
function! AGIT_diffBuf_quit()
    let changed = 0
    execute "normal! \<c-w>k"
    execute "normal! \<c-w>h"
    try
        silent! nunmap <buffer> q
    endtry
    let changed += AGIT_diffBuf_askWrite()
    execute "normal! \<c-w>k"
    execute "normal! \<c-w>l"
    try
        silent! nunmap <buffer> q
    endtry
    let changed += AGIT_diffBuf_askWrite()
    tabclose
    if changed
        execute "normal \<Plug>(agit-reload)"
    endif
endfunction

function! AGIT_tmpStashCheck()
    if exists('*ZFGitTmpStash')
        silent! let stash = ZFGitTmpStashList()
        if !empty(stash)
            echo 'NOTE: you have tmp stashes, use DP to pop, or DR to drop'
            echo "\n"
            call ZFGitTmpStashList()
        endif
    endif
endfunction
function! AGIT_tmpStash()
    if !exists('*ZFGitTmpStash')
        echo 'ZSaberLv0/ZFVimGitUtil is required to perform stash'
        return
    endif
    call ZFGitTmpStash()
    execute "normal \<Plug>(agit-reload)"
endfunction
function! AGIT_tmpStashPop()
    if !exists('*ZFGitTmpStash')
        echo 'ZSaberLv0/ZFVimGitUtil is required to perform stash pop'
        return
    endif
    call ZFGitTmpStashPop()
    execute "normal \<Plug>(agit-reload)"
endfunction
function! AGIT_tmpStashDrop()
    if !exists('*ZFGitTmpStash')
        echo 'ZSaberLv0/ZFVimGitUtil is required to perform stash drop'
        return
    endif
    call ZFGitTmpStashDrop()
    execute "normal \<Plug>(agit-reload)"
endfunction

function! AGIT_log_printMsg()
    let msg = ''
    let hash = agit#extract_hash(getline('.'))
    if hash != ''
        let msg = agit#git#exec('show -s --format=format:%B ' . hash, getcwd())
    endif
    redraw!
    echo msg
    return msg
endfunction
function! AGIT_log_checkout()
    let hash = agit#extract_hash(getline('.'))
    if hash != ''
        call agit#git#exec('checkout ' . hash, getcwd())
        execute "normal \<Plug>(agit-reload)"
    endif
endfunction
function! AGIT_stat_getCurFile()
    let file = getline('.')
    let file = substitute(file, '^ \+', '', '') " `^ +`
    let file = substitute(file, ' \+| .\+$', '', '') " ` +\| .+$`
    return file
endfunction
function! AGIT_stat_open()
    let tabCount = tabpagenr('$')

    let wildignore = &wildignore
    set wildignore=
    call agit#diff#sidebyside(t:git, AGIT_stat_getCurFile(), '')
    let &wildignore = wildignore
    if tabpagenr('$') <= tabCount
        call AGIT_unshallow()
        return
    endif

    execute "normal! \<c-w>h"
    nnoremap <buffer><silent> q :call AGIT_diffBuf_quit()<cr>
    call AGIT_fixEndl()
    execute "normal! \<c-w>l"
    nnoremap <buffer><silent> q :call AGIT_diffBuf_quit()<cr>
    call AGIT_fixEndl()
    normal! ]czz
endfunction
function! AGIT_stat_checkout()
    let file = AGIT_stat_getCurFile()
    if empty(file)
        return
    endif
    if exists('*ZFBackupSave')
        call ZFBackupSave(file)
    endif
    let result = system('git checkout "' . file . '"')
    execute "normal \<Plug>(agit-reload)"
    if match(result, 'Updated .* path from the index') < 0
        echo result
    endif
endfunction
function! AGIT_stat_delete()
    let file = AGIT_stat_getCurFile()
    if empty(file)
        return
    endif
    echo 'delete `' . file . '` ?'
    echo '  (y)es'
    if exists('*ZFBackupSave')
        echo '    (Y)es without backup'
    endif
    echo '  (n)o'
    echo 'choose: '
    let cmd = getchar()
    if cmd != char2nr('y') && cmd != char2nr('Y')
        redraw!
        return
    endif
    if exists('*ZFBackupSave') && cmd != char2nr('Y')
        call ZFBackupSave(file)
    endif
    if isdirectory(file)
        if has('win32') || has('win64')
            call system('rmdir /s/q "' . file . '" >nul 2>&1')
        else
            call system('rm -rf "' . file . '" >/dev/null 2>&1')
        endif
    else
        call delete(file)
    endif
    execute "normal \<Plug>(agit-reload)"
    redraw!
endfunction
function! AGIT_stat_tmpStash()
    let file = AGIT_stat_getCurFile()
    if empty(file)
        return
    endif
    if !exists('*ZFGitTmpStash')
        echo 'ZSaberLv0/ZFVimGitUtil is required to perform stash'
        return
    endif
    if 0
        echo 'stash `' . file . '` ?'
        echo '  (y)es'
        echo '  (n)o'
        echo 'choose: '
        let cmd = getchar()
        if cmd != char2nr('y') && cmd != char2nr('Y')
            redraw!
            return
        endif
        redraw!
    endif
    call ZFGitTmpStash(file)
    execute "normal \<Plug>(agit-reload)"
endfunction

augroup AGIT_augroup
    autocmd!
    autocmd FileType agit,agit_stat,agit_diff
                \  nmap <silent><buffer> q <Plug>(agit-exit)
                \| nmap <silent><buffer> DD <Plug>(agit-reload)
                \| nmap <silent><buffer> U :call AGIT_unshallow({'message':'perform unshallow?'})<cr>
                \| nmap <silent><buffer> DA :call AGIT_tmpStash()<cr>
                \| nmap <silent><buffer> DP :call AGIT_tmpStashPop()<cr>
                \| nmap <silent><buffer> DR :call AGIT_tmpStashDrop()<cr>
                \| setlocal cursorline
    autocmd FileType agit
                \  nmap <silent><buffer> p :call AGIT_log_printMsg()<cr>
                \| nmap <silent><buffer> cc :call AGIT_log_checkout()<cr>
    autocmd FileType agit_stat
                \  nmap <silent><buffer> o :call AGIT_stat_open()<cr>
                \| nmap <silent><buffer> <cr> :call AGIT_stat_open()<cr>
                \| nmap <silent><buffer> DH :call AGIT_stat_checkout()<cr>
                \| nmap <silent><buffer> DS :call AGIT_stat_tmpStash()<cr>
                \| nmap <silent><buffer> dd :call AGIT_stat_delete()<cr>
augroup END

