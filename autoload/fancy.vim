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

" }}}
" Buffer prototype {{{

let s:buffer_prototype = {}

" Returns a new buffer instance.
"
" Arguments:
" - buffer number (as per bufnr spec), use current buffer when not set;
" - number of fancy object if any.
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

" Returns the content of the buffer.
"
" - the line number to start (read from the beginning if not set);
" - the line number to end (read until the end if not set).
fun! s:buffer_read(...) dict abort
  return getbufline(self.name(),
        \ a:0 ? a:1 : 1,
        \ (a:0 == 2) ? a:2 : '$')
endf

" Write text to the buffer.
"
" Arguments:
" - the optional line number to start with;
" - text to write (as per setline spec).
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

" Returns the buffer content with or without indentation.
"
" The arguments are:
" - the indentation level (dedent buffer when value is negative and indent otherwise)
" - the line number to start (read from the beginning if not set)
" - the line number to end (process until the end if not set)
fun! s:buffer_indent(indent, ...) dict abort
  let start_at = a:0 ? a:1 : 1
  let end_at   = (a:0 > 1) ? a:2 : '$'
  return a:indent < 0
        \ ? map(self.read(start_at, end_at), 'fancy#util#dedent_line(v:val, a:indent)')
        \ : map(self.read(start_at, end_at), 'fancy#util#indent_line(v:val, a:indent)')
endf

call s:add_methods('buffer', [
      \ 'getvar', 'setvar', 'name', 'delete', 'read', 'write',
      \ 'exists', 'spec', 'path', 'fancy_id', 'indent'
      \ ])

" }}}
" Matcher prototype {{{

let s:matcher_prototype = {}

fun! s:matcher(...) abort
  let matcher = {
        \ 'start_at': 0,
        \ 'end_at': 0,
        \ 'indent_level': 0,
        \ }
  call extend(matcher, s:matcher_prototype, 'keep')
  return matcher
endf

" Returns the number of the first line of the region.
fun! s:matcher_start_line(...) dict abort
endf

" Returns the number of the last line of the region.
fun! s:matcher_end_line(...) dict abort
endf

" Returns the filetype of the found region.
"
" - the fancy object (can be used to read and extract data from
"   original buffer).
fun! s:matcher_filetype(...) dict abort
endf

" Find fenced region and save it position if any. Return false if
" no region has been found and true otherwise.
fun! s:matcher_find_region(...) dict abort
  let self.start_at     = self.start_line()
  let self.indent_level = indent(self.start_at)
  let self.end_at       = self.end_line()
  return (self.start_at != 0 && self.end_at != 0) ? 1 : 0
endf

fun! s:matcher_search_forward(pattern) dict abort
  return search(a:pattern, 'cnW')
endf

fun! s:matcher_search_backward(pattern) dict abort
  return search(a:pattern, 'bcnW')
endf

call s:add_methods('matcher', [
      \ 'filetype', 'start_line', 'end_line', 'find_region',
      \ 'search_forward', 'search_backward'
      \ ])

" }}}
" Loader prototype {{{

let s:loader_prototype = {}

fun! s:loader() abort
  let loader = {
        \ 'filetypes': {}
        \ }
  call extend(loader, s:loader_prototype, 'keep')
  return loader
endf

fun! s:loader_load(ft) dict abort
  return self.filetypes[a:ft]
endf

fun! s:loader_save(ft, list) dict abort
  let self.filetypes[a:ft] = a:list
endf

fun! s:loader_is_cached(ft) dict abort
  return has_key(self.filetypes, a:ft)
endf

fun! s:loader_is_defined(ft) dict abort
  let func = 'autoload/fancy/ft/'.a:ft.'.vim'
  return !empty(globpath(&rtp, func))
endf

fun! s:loader_load_by_filetype(ft) dict abort
  if self.is_cached(a:ft)
    return self.load(a:ft)

  elseif self.is_defined(a:ft)
    let matchers = fancy#ft#{a:ft}#matchers()
    call self.save(a:ft, matchers)
    return matchers
  endif
endf

call s:add_methods('loader', [
      \ 'load', 'save', 'is_cached', 'is_defined', 'load_by_filetype'
      \ ])

" }}}
" Fancy prototype {{{

let s:fancy_prototype = {}

fun! s:fancy() abort
  let matchers = s:loader().load_by_filetype(&filetype)
  if empty(matchers)
    call s:error(printf('%s: no available matcher', &filetype))
    return
  endif

  let found = 0
  for matcher in matchers
    if matcher.find_region()
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
        \ 'matcher': matcher,
        \ 'buffer': s:buffer(),
        \ }
  call extend(fancy, s:fancy_prototype, 'keep')

  call add(s:fancy_objects, fancy)
  return fancy
endf

fun! s:fancy_filetype() dict abort
  let filetype = self.matcher.filetype(self)
  return empty(filetype)
        \ ? self.buffer.getvar('&filetype')
        \ : filetype
endf

fun! s:fancy_text() dict abort
  return self.buffer.indent(
        \ -self.matcher.indent_level,
        \  self.matcher.start_at + 1,
        \  self.matcher.end_at - 1)
endf

fun! s:fancy_destroy() dict abort
  call remove(s:fancy_objects, index(s:fancy_objects, self))
endf

call s:add_methods('fancy', ['filetype', 'text', 'destroy'])


" Returns fancy object bound to buffer.
fun! s:lookup_fancy(buffer)
  let fancy_id = a:buffer.fancy_id()
  let found = filter(copy(s:fancy_objects), 'v:val["id"] == fancy_id')
  if empty(found)
    call s:error('Original buffer does no longer exist! Aborting!')
    return
  endif
  return found[0]
endf

" }}}
" Fancy public interface {{{

fun! fancy#matcher() abort
  return s:matcher()
endf

fun! fancy#fancy() abort
  return s:fancy()
endf

fun! fancy#init() abort
  " Create a new fancy instance for the current buffer. Exit silently when
  " fenced region does not found.
  let fancy = fancy#fancy()
  if (type(fancy) != type({}))
    return
  endif

  " Create a new temporary file and open it in split.
  let name = tempname()
  exe 'split '.name

  " Bind buffer to the fancy object and
  " - copy fenced region into it;
  " - detect and set filetype;
  " - ensure the buffer is wiped out when it's no longer displayed
  "   in a window;
  " - mark buffer as nomodified, to prevent warning when trying to close it;
  " - disable swap file for the buffer;
  " - show buffer in the buffer list;
  " - rename buffer according with its spec.
  let buffer = s:buffer(name, fancy.id)
  call buffer.write(fancy.text())
  call buffer.setvar('&ft', fancy.filetype())
  call buffer.setvar('&bufhidden', 'wipe')
  call buffer.setvar('&modified', 0)
  call buffer.setvar('&swapfile', 0)
  call buffer.setvar('&buflisted', 1)
  sil exe 'file '.buffer.spec()
endf

fun! fancy#sync(bufnr) abort
  " Get buffer and related fancy object.
  let buffer = s:buffer(a:bufnr)
  let fancy  = s:lookup_fancy(buffer)

  " Go to original buffer.
  let winnr = bufwinnr(fancy.buffer.name())
  if (winnr != winnr())
    exe 'noa' winnr 'wincmd w'
  endif

  " Sync any changes.
  if (fancy.matcher.end_at - fancy.matcher.start_at > 1)
    exe printf('%s,%s delete _', fancy.matcher.start_at + 1, fancy.matcher.end_at - 1)
  endif
  call append(fancy.matcher.start_at, buffer.indent(fancy.matcher.indent_level))

  " Restore the original cursor position.
  call setpos('.', fancy.buffer.pos)

  " Update start/end block position.
  call fancy.matcher.find_region()
endf

fun! fancy#write(bufnr) abort
  let buffer = s:buffer(a:bufnr)
  sil exe 'write! '.buffer.path()
  call buffer.setvar('&modified', 0)
endf

fun! fancy#destroy(bufnr) abort
  let buffer = s:buffer(a:bufnr)
  let fancy  = s:lookup_fancy(buffer)
  call fancy.destroy()
endf

" }}}
