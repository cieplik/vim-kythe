let g:kythe_bin    = "kythe"
let g:kwazthis_bin = "kythe.kwazthis"
let g:kythe_api    = "http://127.0.0.1:8090"

function! Kwazthis()
  let [dummy, line, col; rest] = getcurpos()

  let cmd = g:kwazthis_bin . " --api " . g:kythe_api . " --column " . col . " --line " . line . " --path " . expand('%:p')
  echom cmd
  for l in systemlist(cmd)
    echom l
    if l =~ '\C\v^[{].*'
      let out = ParseJSON(l)

      if out['kind'] == 'ref'
        return [1, out['node']['ticket']]
      endif
    endif
  endfor

  return [0, 0]
endfunction

function! Kdefinition(ticket)
  echom "Ticket: " . a:ticket

  for l in systemlist(g:kythe_bin . ' --api ' . g:kythe_api . ' --json xrefs ' . ' ' . a:ticket)
    if l =~ '\C\v^[{].*'
      let def   = ParseJSON(l)['cross_references'][a:ticket]['definition'][0]
      let root  = substitute(def['parent'], '\v.*root\=([^?]+).*', '\1', 'g')
      let path  = substitute(def['parent'], '\v.*path\=([^?]+).*', '\1', 'g')
      let start = def['start']

      exec 'edit ' . (path[0] == '/' ? path : root . '/' . path)
      call setpos('.', [0, start.line_number, start.column_offset + 1, 0])
      break
    endif
  endfor
endfunction

function! KdefinitionIfExists()
  let [rc, ticket] = Kwazthis()

  if rc
    call Kdefinition(ticket)
  endif
endfunction

