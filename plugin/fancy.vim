" Guard {{{

if exists('g:loaded_fancy') || &cp || version < 700
  finish
endif
let g:loaded_fancy = 1

" }}}
" Autocommands {{{

augroup fancy_files
  au!
  au BufWriteCmd  fancy://**  call fancy#write(expand('<amatch>'))
  au BufLeave     fancy://**  call fancy#sync()
  au BufWipeout   fancy://**  call fancy#destroy(expand('<abuf>'))
  au BufEnter     fancy://**
        \ setl bufhidden=wipe bl noswapfile |
        \ nnore <buffer> q :write<bar>close<cr>
augroup END

augroup fancy_markdown
  au!
  au FileType markdown nnore <s-e> :call fancy#edit()<cr>
augroup END

" }}}
