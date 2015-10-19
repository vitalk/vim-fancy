" Fancy utilities.


fun! fancy#util#indent_line(line, indent)
  return printf('%*s%s', a:indent, a:indent ? ' ' : '', a:line)
endf

fun! fancy#util#dedent_line(line, indent)
  return substitute(a:line, '^\s\{'.a:indent.'\}', '', '')
endf
