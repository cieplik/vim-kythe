let g:kythe_bin    = "kythe"
let g:kwazthis_bin = "kythe.kwazthis"

function! Kwazthis()
  let [dummy, line, col; rest] = getcurpos()

  for l in systemlist(g:kwazthis_bin . " --column " . col . " --line " . line . " --path " . "kythe/cxx/common/indexing/KytheClaimClient.cc")
    let out = ParseJSON(l)

    if out['kind'] == 'ref'
      let ticket = out['node']['ticket']
      break
    endif
  endfor

  if exists("ticket")
    echom "Ticket: " . ticket

    for l in systemlist(g:kythe_bin . ' --json xrefs ' . ticket)
      if l =~ '\v[{].*'
        let def  = ParseJSON(l)['cross_references'][ticket]['definition'][0]
        let root = substitute(def['parent'], '\v.*root\=([^?]+).*', '\1', 'g')
        let path = substitute(def['parent'], '\v.*path\=([^?]+).*', '\1', 'g')

        exec 'edit ' . root . '/' . path
        exec 'normal ' . def['start']['line_number'] . 'G'
        break
      endif
    endfor
  endif
endfunction

