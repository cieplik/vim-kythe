let g:kythe_bin    = "kythe"
let g:kwazthis_bin = "kythe.kwazthis"
let g:kythe_api    = "http://127.0.0.1:8090"

function! Kwazthis()
  let [dummy, line, col; rest] = getcurpos()

  let cmd = g:kwazthis_bin . " --api " . g:kythe_api . " --column " . col . " --line " . line . " --path " . expand('%:p')
  let lines = []
  " echom cmd
  for l in systemlist(cmd)
    echom l
    if l =~ '\C\v^[{].*'
      let lines += [webapi#json#decode(l)]
    endif
  endfor

  return lines
endfunction

let priorities = {
\ "ticket": 100,
\ "snippet": 200,
\ "kind": 250,
\ "parent": 300,
\ "start": 800,
\ "end": 850,
\ "snippet_start": 900,
\ "snippet_end": 950,
\ "___": 1000
\ }

function! Priority(field)
  return has_key(g:priorities, a:field) ? g:priorities[a:field] : g:priorities['___']
endfunction

function! ByPriority(lhs, rhs)
  return Priority(a:lhs) - Priority(a:rhs)
endfunction

function! s:SortKeys(keys)
  call sort(a:keys, 'ByPriority')
  return a:keys
endfunction

function! ToJson(input, indent, b64)
  let json = ""
  let myindent = a:indent . '  '
    if type(a:input) == type({})
      let json .= "{\n"
      let first = 1
      for key in s:SortKeys(keys(a:input))
          let json .= first ? '' : ",\n"
          let json .= myindent . '"' . (type(key) == type('') ? substitute(key, '"', '\\"','g') : key) . '": '
          let json .= ToJson(a:input[key], myindent, key == 'value')

          let first = 0
      endfor
      let json .= "\n" . a:indent . "}"
    elseif type(a:input) == type([])
      let json .= "[\n"
      let first = 1
      for e in a:input
        let json .= first ? "" : ",\n"
        let json .= myindent . ToJson(e, myindent, 0)

        let first = 0
      endfor

      let json .= "\n" . a:indent . "]"
    elseif type(a:input) == type('')
        let json .= '"'.substitute(a:b64 ? webapi#base64#b64decode(a:input) : a:input, '"', '\\"','g').'"'
    else
        let json .= '"'.a:input.'"'
    endif
  return json
endfunction

function! Kwaz()
  let lines = Kwazthis()
  vne
  set ft=vim-kythe
  put! =ToJson(lines, '', 0)
endfunction

function! Kkti(lnum)
  let indent_expr =  '\v^([ ]*).*'
  let indent = substitute(a:lnum, indent_expr, '\1', '')

  let key_expr = '\v[^"]+"([^"]+)":.*'
  let key    = match(getline(a:lnum), key_expr) != -1 ? substitute(a:lnum, key_expr, '\1', '') : ''
  let ticket = substitute(a:lnum, '\v.*"(kythe:[^"]+)".*', '\1', '')

  return [key, ticket, indent]
endfunction

function! Knode()
  let [key, ticket, indent] = Kkti(getline('.'))

  let node   = webapi#json#decode(system(g:kythe_bin . ' --api ' . g:kythe_api . ' --json node ' . ticket))[0]
  let repl   =   indent . (key != '' ? '"vim-kythe/' . key . '": ' : '') . ToJson(node, indent, 0)

  let pos = getpos('.')
  delete | put! =repl
  call setpos('.', pos)
endfunction

function! PutAfter(node, lnum)
  let pos = getpos(a:lnum)
  let suffix = ''

  if match(getline('.'), '\v.*,\s*$') != -1
    let suffix = ','
  else
    put =',' | normal! kJ$X
  endif

  put =a:node . suffix
  call setpos('.', pos)
endfunction

function! Kxrefs()
  let [key, ticket, indent] = Kkti(getline('.'))

  let cmd = g:kythe_bin . ' --api ' . g:kythe_api . ' --json xrefs ' . ticket . ' 2>/dev/null'
  let xrefs = webapi#json#decode(system(cmd))
  if (has_key(xrefs, 'cross_references'))
    let repl =   indent . '"cross_references": ' . ToJson(xrefs['cross_references'], indent, 0)
    call PutAfter(repl, '.')
  else
    echo xrefs
  endif
endfunction

function! Kedges()
  let [key, ticket, indent] = Kkti(getline('.'))

  let cmd = g:kythe_bin . ' --api ' . g:kythe_api . ' --json edges ' . ticket . ' 2>/dev/null'
  let xrefs = webapi#json#decode(system(cmd))
  if (has_key(xrefs, 'edge_set'))
    let repl = indent . '"edges": ' . ToJson(xrefs['edge_set'], indent, 0)
    call PutAfter(repl, '.')
  else
    echo xrefs
  endif
endfunction
