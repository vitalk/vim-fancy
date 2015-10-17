" Language: Markdown
" Author: Vital Kudzelka
" License: MIT

fun! fancy#ft#markdown#matchers()
  " Github Flavored Markdown {{{

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

  " }}}
  " Bitbucket {{{

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

  " }}}

  return [
        \ bitbucket_markdown,
        \ github_flavored_markdown,
        \ ]
endf
