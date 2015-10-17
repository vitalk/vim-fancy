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
  au BufLeave     fancy://**  call fancy#sync(expand('<amatch>'))
  au BufWipeout   fancy://**  call fancy#destroy(expand('<amatch>'))
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

let github_flavored_markdown = fancy#matcher()

fun! github_flavored_markdown.start_line(...) dict abort
  return self.search_backward('^\(\s\+\)\?```\w\+$')
endf

fun! github_flavored_markdown.end_line(indent, ...) dict abort
  return self.search_forward('^\(\s\{'.a:indent.'\}\)\?```$')
endf

fun! github_flavored_markdown.filetype(fancy) dict abort
  let text = join(a:fancy.buffer.read(
        \ a:fancy.matcher.start_at,
        \ a:fancy.matcher.start_at),
        \ '\n')
  return substitute(text, '\(\s\+\)\?```', '', '')
endf


let bitbucket_markdown = fancy#matcher()

fun! bitbucket_markdown.start_line(...) dict abort
  return self.search_backward('\(```\n\)\@<=\#!\w\+$')
endf

fun! bitbucket_markdown.end_line(...) dict abort
  return self.search_forward('^```$')
endf

fun! bitbucket_markdown.filetype(fancy) dict abort
  let text = join(a:fancy.buffer.read(
        \ a:fancy.matcher.start_at,
        \ a:fancy.matcher.start_at),
        \ '\n')
  return substitute(text, '\#!', '', '')
endf

let filetypes = {}
let filetypes.markdown = [
      \ bitbucket_markdown,
      \ github_flavored_markdown,
      \ ]

let g:fancy_filetypes = get(g:, 'fancy_filetypes', filetypes)

" }}}
