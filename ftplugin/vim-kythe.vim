set foldmethod=syntax

function! FoldText()
  " let lines = getline(v:foldstart, v:foldend)
  " let idx = match(lines, '"snippet":')

  " if idx != -1
  "   return v:folddashes . substitute(lines[idx], '\v.*"snippet":[^"]*"([^"]+)"', '\1', '')
  " endif

  return foldtext()
endfunction

set foldtext=FoldText()

map <buffer> <LocalLeader>n :silent call Knode()<CR>
map <buffer> <LocalLeader>x :silent call Kxrefs()<CR>
map <buffer> <LocalLeader>e :silent call Kedges()<CR>
" map <buffer> K :silent call Kwaz()<CR>
