
personal configs for [cohama/agit.vim](https://github.com/cohama/agit.vim)

usage:

```
Plug 'cohama/agit.vim'
Plug 'ZSaberLv0/agit.vim.config' " must after agit.vim
command! -nargs=* -complete=dir ZFGitDiff :call AGIT_main(<q-args>)
command! -nargs=* -complete=file ZFGitDiffFile :call AGIT_file(<q-args>)
```

