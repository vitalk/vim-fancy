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
" Configuration {{{

let github_flavored_markdown = {}
let github_flavored_markdown.start_at = '^```\w\+$'
let github_flavored_markdown.end_at = '^```$'
fun! github_flavored_markdown.filetype(fancy)
  let text = join(a:fancy.buffer.read(a:fancy.start_at, a:fancy.start_at), '\n')
  return substitute(text, '```', '', '')
endf

let filetypes = {}
let filetypes.markdown = [github_flavored_markdown]

let g:fancy_filetypes = get(g:, 'fancy_filetypes', filetypes)

" }}}
