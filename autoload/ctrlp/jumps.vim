" =============================================================================
" File:          autoload/ctrlp/sample.vim
" Description:   Example extension for ctrlp.vim
" =============================================================================

" To load this extension into ctrlp, add this to your vimrc:
"
"     let g:ctrlp_extensions = ['sample']
"
" Where 'sample' is the name of the file 'sample.vim'
"
" For multiple extensions:
"
"     let g:ctrlp_extensions = [
"         \ 'my_extension',
"         \ 'my_other_extension',
"         \ ]

" Add this extension's settings to g:ctrlp_ext_vars
"
" Required:
"
" + init: the name of the input function including the brackets and any
"         arguments
"
" + accept: the name of the action function (only the name)
"
" + lname & sname: the long and short names to use for the statusline
"
" + type: the matching type
"   - line : match full line
"   - path : match full line like a file or a directory path
"   - tabs : match until first tab character
"   - tabe : match until last tab character
"
" Optional:
"
" + enter: the name of the function to be called before starting ctrlp
"
" + exit: the name of the function to be called after closing ctrlp
"
" + opts: the name of the option handling function called when initialize
"
" + sort: disable sorting (enabled by default when omitted)
"
" + specinput: enable special inputs '..' and '@cd' (disabled by default)
"
" Load guard
if ( exists('g:loaded_ctrlp_jumps') && g:loaded_ctrlp_jumps )
	\ || v:version < 700 || &cp
	finish
endif
let g:loaded_ctrlp_jumps = 1

call add(g:ctrlp_ext_vars, {
	\ 'init': 'ctrlp#jumps#init()',
	\ 'accept': 'ctrlp#jumps#accept',
	\ 'lname': 'Jumps List',
	\ 'sname': 'jmp',
	\ 'type': 'line',
	\ 'enter': 'ctrlp#jumps#enter()',
	\ 'exit': 'ctrlp#jumps#exit()',
	\ 'opts': 'ctrlp#jumps#opts()',
	\ 'sort': 0,
	\ 'specinput': 0,
	\ })


" Provide a list of strings to search in
"
" Return: a Vim's List
"

let s:bufnr = -1
let s:jumps = ''
let s:jump_lines = []

function! ctrlp#jumps#init()
    call s:get_jump_lines()
    call s:syntax()
	return reverse(s:jump_lines)
endfunction

function! s:syntax()
    hi link JumpFile Comment
    syn match JumpFile '\v^([\-\+]\d+|\>)([^\|]+)'
endfunction

function! s:parseJumpsLine(line)
    let elements = matchlist(a:line, '\v^(.)\s*(\d+)\s+(\d+)\s+(\d+)\s*(.*)$')
    if empty(elements)
        return {}
    endif
    let linePrevBuffer = join(getbufline(s:bufnr, elements[3]))
    let n = bufnr(fnamemodify(elements[5], ':p'))
    if n == s:bufnr || n == -1
        let fname = bufname(s:bufnr)
        let text  = elements[5]
    else
        let fname = elements[5]
        let path = fnamemodify(bufname(n), ':p')
        let lines = []
        if (filereadable(path))
            let lines = readfile(path)
        endif
        let text = ''
        if (elements[3] <= len(lines))
            let text = lines[elements[3] - 1]
        endif
    endif
    return  {
                \   'prefix': elements[1],
                \   'count' : elements[2],
                \   'lnum'  : elements[3],
                \   'fname' : fname,
                \   'text'  : printf('%s|%d:%d|%s', fname, elements[3], elements[4], text),
                \ }
endfunction

" The action to perform on the selected string
"
" Arguments:
"  a:mode   the mode that has been chosen by pressing <cr> <c-v> <c-t> or <c-x>
"           the values are 'e', 'v', 't' and 'h', respectively
"  a:str    the selected string
"
function! ctrlp#jumps#accept(mode, str)
	" For this example, just exit ctrlp and run help
	call ctrlp#exit()
    let pattern = '\v\c^(.)(\d*).*$'
    let sign = substitute(a:str, pattern, '\1', 'g')
    let n = substitute(a:str, pattern, '\2', 'g')

    if sign != '>'
        if (sign == '-')
            execute "normal " . n . "\<c-o>"
        else
            execute "normal " . n . "\<c-i>"
        endif
    endif
endfunction

function! s:get_jump_lines()
	let input = split(s:jumps, "\n")
    let s:jump_lines = []
    let sign = '-'
    for txt in input
        let item = s:parseJumpsLine(txt)
        if item != {}
            if (item.prefix == '>')
                let sign = '+'
                let text = ">\t"
            else
                let text = sign . item.count
            endif
            let text = text . "\t" . item.text
            call add(s:jump_lines, text)
        endif
    endfor
endfunction

" (optional) Do something before enterting ctrlp
function! ctrlp#jumps#enter()
    redir => s:jumps | silent jumps | redir end
    let s:bufnr = bufnr('%')
    call ctrlp#init(ctrlp#jumps#id())
endfunction


" (optional) Do something after exiting ctrlp
function! ctrlp#jumps#exit()
    let s:jumps = ''
    let s:jump_lines = []
endfunction

function! ctrlp#jumps#start()
    redir => s:jumps | silent jumps | redir end
    call s:get_jump_lines()
    let s = ""
    for i in reverse(s:jump_lines)
        if (i =~ '\v^[\-\>]')
            break
        endif
        let s = s . "\<c-k>"
    endfor

    let s:jump_lines = reverse(s:jump_lines)

    execute "normal :call ctrlp#init(ctrlp#jumps#id())\<cr>" . s
endfunction

" (optional) Set or check for user options specific to this extension
function! ctrlp#jumps#opts()
endfunction


" Give the extension an ID
let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)

" Allow it to be called later
function! ctrlp#jumps#id()
	return s:id
endfunction


" Create a command to directly call the new search type
"
" Put this in vimrc or plugin/sample.vim
" command! CtrlPSample call ctrlp#init(ctrlp#jumps#id())


" vim:nofen:fdl=0:ts=4:sw=4:sts=4
