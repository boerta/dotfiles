" An example for a gvimrc file.
" The commands in this are executed when the GUI is started.
"
" Maintainer:	Bram Moolenaar <Bram@vim.org>
" Last change:	2000 Mar 29
"
" To use it, copy it to
"     for Unix and OS/2:  ~/.gvimrc
"             for Amiga:  s:.gvimrc
"  for MS-DOS and Win32:  $VIM\_gvimrc
"           for OpenVMS:  sys$login:.gvimrc

" Make external commands work through a pipe instead of a pseudo-tty
"set noguipty

" set the X11 font to use
" set guifont=-misc-fixed-medium-r-normal--14-130-75-75-c-70-iso8859-1


" Make command line two lines high
set ch=2
" Make shift-insert work like in Xterm
map <S-Insert> <MiddleMouse>
map! <S-Insert> <MiddleMouse>
map <F5> ggVGg?

" Only do this for Vim version 5.0 and later.
if version >= 500

	" be not-very VI compatible
	set nocp

  " I like highlighting strings inside C comments
  let c_comment_strings=0

  " Switch on syntax highlighting.
  set nocompatible
  syntax on
  set vb
  " tabbing.
  " number of spaces a <Tab> in the text stands for
  "	(local to buffer)
  "	number of spaces used for each step of (auto)indent
  "	(local to buffer)
  "	a <Tab> in an indent inserts 'shiftwidth' spaces
  " 	set sta	nosta
  "	softtabstop	if non-zero, number of spaces to insert for a <Tab>
  "	(local to buffer)
	set ts=4
	set sw=4
	set sta
	set et
	set sts=4
	
	"set backspace can delete backwards beyond insert
	set bs=2
	
	" show partial commands
	set sc

	" show line numbers
	set nu

	" show cursor line
	set cul

  " Switch on search pattern highlighting.
  set nohlsearch

	" ignore case when searching
	set ic

	" ignore 'ignorcase' when pattern has uppercase letters
	set scs

	"show match for partly typed search command
	set is
	
	" focus follows mouse
	set mousef

	" autoindent/smartindent
	set ai
	set si

	" linebreak

	set lbr
  
  " For Win32 version, have "K" lookup the keyword in a help file
  "if has("win32")
  "  let winhelpfile='windows.hlp'
  "  map K :execute "!start winhlp32 -k <cword> " . winhelpfile <CR>
  "endif

  " Hide the mouse pointer while typing
  set mousehide

  set tags+=~/.vim/systags
  set tags+=~/skole/master/trunk/src/TAGS

  " Set nice colors
  " background for normal text is light grey
  " Text below the last line is darker grey
  " Cursor is green
  " Constants are not underlined but have a slightly lighter background
  highlight Normal guibg=black guifg=white
  highlight Cursor guibg=Green guifg=NONE
  highlight NonText guibg=black
  highlight Constant gui=NONE guibg=black
  highlight Special gui=NONE
  highlight Folded guibg=black guifg=cyan
"  highlight Comment guibg=black guifg=yellow

   inoremap <Nul> <C-x><C-o>

" Recursive grep under \*
map \* "syiw:Grep^Rs<cr>
function! Grep(name)
   let l:pattern = input("Other pattern: ")
   "let l:_name = substitute(a:name, "\\s", "*", "g")
   "  let l:list=system("grep -nIR '".a:name."' * | grep -v 'svn-base' | grep
   "  '" .l:pattern. "' | cat -n -")
   "    let l:num=strlen(substitute(l:list, "[^\n]", "", "g"))
   if l:num < 1
      echo "'".a:name."' not found"
      return
   endif

   echo l:list
   let l:input=input("Which?\n")

   if strlen(l:input)==0
      return
   endif

   if strlen(substitute(l:input, "[0-9]", "", "g"))>0
      echo "Not a number"
      return
   endif

   if l:input<1 || l:input>l:num
      echo "Out of range"
      return
   endif

   let l:line=matchstr("\n".l:list, "".l:input."\t[^\n]*")
   let l:lineno=matchstr(l:line,":[0-9]*:")
   let l:lineno=substitute(l:lineno,":","","g")
   "echo
   """.l:line
   let l:line=substitute(l:line, "^[^\t]*\t", "", "")
   "echo
   """.l:line
   let l:line=substitute(l:line, "\:.*", "", "")
   "echo
   """.l:line
   "echo
   ""\n".l:line
   execute ":e ".l:line
   execute "normal ".l:lineno."gg"
endfunction
command! -nargs=1 Grep :call Grep("<args>")

" recursive find for filename under \f
map \f "syiw:Find^Rs<cr>
function! Find(name)
   let l:_name = substitute(a:name, "\\s", "*", "g")
   let l:list=system("find . -iname '*".l:_name."*' -not -name \"*.class\" -and -not -name \"*.swp\" | perl -ne 'print \"$.\\t$_\"'")
   let l:num=strlen(substitute(l:list, "[^\n]", "", "g"))
   if l:num < 1
      echo "'".a:name."' not found"
      return
   endif

   if l:num != 1
      echo l:list
      let l:input=input("Which ? (=nothing)\n")

      if strlen(l:input)==0
	 return
      endif

      if strlen(substitute(l:input, "[0-9]", "", "g"))>0
	 echo "Not a number"
	 return
      endif

      if l:input<1 || l:input>l:num
	 echo "Out of range"
	 return
      endif

      let l:line=matchstr("\n".l:list, "\n".l:input."\t[^\n]*")
   else
      let l:line=l:list
   endif

   let l:line=substitute(l:line, "^[^\t]*\t./", "", "")
   "echo
   """.l:line
   execute ":e ".l:line
endfunction
command! -nargs=1 Find :call Find("<args>")
endif

colorscheme gruvbox

au! BufNewfile *.tex
"au BufNewFile *.tex | read ~/blank.tex |set makeprg=latex\% |set ft=tex
au BufNewFile *.tex : read ~/.templates/latex.tpl | set ft=tex

set foldmethod=indent
set foldlevelstart=99
set gfn=monospace\ 10

filetype plugin on
:let g:tex_flavor="latex"
set grepprg=grep\ -nH\ $*

autocmd BufRead *.py set smartindent cinwords=if,elif,else,for,while,try,except,finally,def,class

"imap { {<C-M>}<Up><C-M>
"imap <C-BS> <Del><Del><BS><BS>
