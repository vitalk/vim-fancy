if exists('g:loaded_fancy_edit') || &cp || version < 700
  finish
endif
let g:loaded_fancy_edit = 1


augroup fancy_edit
  au!
  au BufWriteCmd  fancy://**  call fancy#write(expand('<amatch>'))
  au BufLeave     fancy://**  call fancy#sync()
  au BufWipeout   fancy://**  call fancy#destroy(expand('<abuf>'))
  au BufEnter     fancy://**
        \ setl bufhidden=wipe bl noswapfile |
        \ nnore <buffer> q :write<bar>close<cr>
augroup END


augroup fancy_edit_markdown
  au!
  au FileType markdown nnore <s-e> :call fancy#edit()<cr>
augroup END
