" Internal variables and functions {{{

let s:id = 0
let s:fancy_objects = []


fun! s:error(message)
  echohl ErrorMsg | echomsg a:message | echohl NONE
  let v:errmsg = a:message
endf

fun! s:function(name) abort
  return function(a:name)
endf

fun! s:add_methods(namespace, method_names) abort
  for name in a:method_names
    let s:{a:namespace}_prototype[name] = s:function('s:'.a:namespace.'_'.name)
  endfor
endf

fun! s:get_id()
  let s:id += 1
  return s:id
endf

fun! s:indent_line(line, indent)
  return printf('%*s%s', a:indent, a:indent ? ' ' : '', a:line)
endf

fun! s:dedent_line(line, indent)
  return substitute(a:line, '^\s\{'.a:indent.'\}', '', '')
endf

fun! s:indent_lines(lines, indent)
  return a:indent < 0 ?
        \ map(lines, 's:dedent_line(v:val, indent)') :
        \ map(lines, 's:indent_line(v:val, indent)')
endf

" }}}
" Buffer prototype {{{

let s:buffer_prototype = {}

fun! s:buffer(...) abort
  let buffer = {
        \ '#': bufnr(a:0 ? a:1 : '%'),
        \ 'id': (a:0 > 1 && a:2) ? a:2 : 0,
        \ 'pos': getpos('.')
        \ }
  call extend(buffer, s:buffer_prototype, 'keep')
  return buffer
endf

fun! s:buffer_getvar(var) dict abort
  return getbufvar(self['#'], a:var)
endf

fun! s:buffer_setvar(var, value) dict abort
  return setbufvar(self['#'], a:var, a:value)
endf

fun! s:buffer_spec() dict abort
  let full = bufname(self['#'])
  if full =~# '^fancy://.*//\d\+'
    let path = substitute(full, '^fancy://\(.*\)//\d\+', '\1', '')
  elseif full != ''
    let path = fnamemodify(full, ':p')
  else
    let path = ''
  endif

  let id = (full =~# '^fancy://.*//\d\+')
        \ ? substitute(full, '^fancy://.*//\(\d\+\)', '\1', '')
        \ : self.id
  return 'fancy://'.path.'//'.id
endf

fun! s:buffer_name() dict abort
  return self.path()
endf

fun! s:buffer_path() dict abort
  return substitute(self.spec(), '^fancy://\(.*\)//\d\+', '\1', '')
endf

fun! s:buffer_fancy_id() dict abort
  return substitute(self.spec(), '^fancy://.*//\(\d\+\)', '\1', '')
endf

fun! s:buffer_exists() dict abort
  return bufexists(self.spec()) && (bufwinnr(self.spec()) != -1)
endf

fun! s:buffer_delete() dict abort
  call delete(self.name())

  if fnamemodify(bufname('$'), ':p') ==# self.name()
    sil exe 'bwipeout '.bufnr('$')
  endif
endf

fun! s:buffer_read(...) dict abort
  return getbufline(self.name(),
        \ a:0 ? a:1 : 1,
        \ (a:0 == 2) ? a:2 : '$')
endf

fun! s:buffer_write(...) dict abort
  if empty(a:0)
    return
  elseif a:0 == 1
    let [lnum, text] = [1, a:1]
  else
    let [lnum, text] = [a:1, a:2]
  endif
  return setline(lnum, text)
endf

fun! s:buffer_indent(...) dict abort
  let indent = a:0 ? a:1 : 0
  let start_at = (a:0 > 1) ? a:2 : 1
  let end_at = (a:0 == 3) ? a:3 : '$'
  return indent < 0 ?
        \ map(self.read(start_at, end_at), 's:dedent_line(v:val, indent)') :
        \ map(self.read(start_at, end_at), 's:indent_line(v:val, indent)')
endf

call s:add_methods('buffer', [
      \ 'getvar', 'setvar', 'name', 'delete', 'read', 'write',
      \ 'exists', 'spec', 'path', 'fancy_id', 'indent'
      \ ])

" }}}
" Fancy prototype {{{

let s:fancy_prototype = {}

fun! s:fancy() abort
  let candidates = s:get_filetype_options(&filetype)
  if empty(candidates)
    call s:error(printf('%s: no available search options', &filetype))
    return
  endif

  let found = 0
  for search_options in candidates
    let [start_at, end_at] = s:get_region_bounds(search_options)
    if start_at != 0 && end_at != 0
      let found = 1
      break
    endif
  endfor

  if !found
    call s:error('No fenced block found! Aborting!')
    return
  endif

  let fancy = {
        \ 'id': s:get_id(),
        \ 'options': search_options,
        \ 'start_at': start_at,
        \ 'end_at': end_at,
        \ 'buffer': s:buffer(),
        \ 'indent_level': indent(start_at)
        \ }
  call extend(fancy, s:fancy_prototype, 'keep')

  call add(s:fancy_objects, fancy)
  return fancy
endf

fun! s:fancy_sync() dict abort
  return s:sync()
endf

fun! s:fancy_filetype() dict abort
  let filetype = self.options.filetype(self)
  return empty(filetype)
        \ ? self.buffer.getvar('&filetype')
        \ : filetype
endf

fun! s:fancy_text() dict abort
  return self.buffer.indent(
        \ -self.indent_level,
        \ self.start_at + 1,
        \ self.end_at - 1)
endf

fun! s:fancy_destroy() dict abort
  call remove(s:fancy_objects, index(s:fancy_objects, self))
endf

call s:add_methods('fancy', ['sync', 'filetype', 'text', 'destroy'])


fun! s:lookup_fancy(id)
  let found = filter(copy(s:fancy_objects), 'v:val["id"] == a:id')
  if empty(found)
    call s:error('Original buffer does no longer exist! Aborting!')
    return
  endif
  return found[0]
endf

fun! s:get_filetype_options(ft)
  if has_key(g:fancy_filetypes, a:ft)
    return g:fancy_filetypes[a:ft]
  endif
  return []
endf

fun! s:search_forward(pattern)
  return search(a:pattern, 'cnW')
endf

fun! s:search_backward(pattern)
  return search(a:pattern, 'bcnW')
endf

fun! s:get_region_bounds(options)
  let start_at = s:search_backward(a:options.start_at)
  let end_at   = s:search_forward(a:options.end_at)
  return [start_at, end_at]
endf

fun! s:edit()
  let fancy = fancy#fancy()
  if (type(fancy) != type({}))
    return
  endif

  let name = tempname()
  exe 'split '.name
  let buffer = s:buffer(name, fancy.id)

  call buffer.setvar('&ft', fancy.filetype())
  call buffer.setvar('&bufhidden', 'wipe')
  call buffer.write(fancy.text())

  sil exe 'file '.buffer.spec()
  setl nomodified
endf

fun! s:destroy(...)
  let bufnr = a:0 ? a:1[0] : '%'
  let buffer = s:buffer(bufnr)
  let fancy = s:lookup_fancy(buffer.fancy_id())
  call fancy.destroy()
endf

fun! s:sync(...)
  let bufnr = a:0 ? a:1[0] : '%'
  let buffer = s:buffer(bufnr)
  let fancy = s:lookup_fancy(buffer.fancy_id())

  " Go to original buffer.
  let winnr = bufwinnr(fancy.buffer.name())
  if (winnr != winnr())
    exe 'noa' winnr 'wincmd w'
  endif

  " Sync any changes.
  if (fancy.end_at - fancy.start_at > 1)
    exe printf('%s,%s delete _', fancy.start_at + 1, fancy.end_at - 1)
  endif
  call append(fancy.start_at, buffer.indent(fancy.indent_level))

  " Restore the original cursor position.
  call setpos('.', fancy.buffer.pos)

  " Update start/end block position.
  let [fancy.start_at, fancy.end_at] = s:get_region_bounds(fancy.options)
endf

fun! s:write(...)
  let bufnr = a:0 ? a:1[0] : '%'
  sil exe 'write! '.s:buffer(bufnr).path()
  setl nomodified
endf

" }}}
" Funcy public interface {{{

fun! fancy#fancy() abort
  return s:fancy()
endf

fun! fancy#edit() abort
  return s:edit()
endf

fun! fancy#sync(...) abort
  return s:sync(a:000)
endf

fun! fancy#write(...) abort
  return s:write(a:000)
endf

fun! fancy#destroy(...) abort
  return s:destroy(a:000)
endf

" }}}
