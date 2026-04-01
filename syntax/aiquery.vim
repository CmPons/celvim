" Vim syntax file
" Language: Celvim AI Query
" Latest Revision: 1 April 2026

if exists("b:current_syntax")
  finish
endif

" User prompt line
syntax match aiQueryUser /^ :.*/

syntax region aiQueryBot start=/^󰚩 : / end=/\ze^ : \|\%$/ keepend contains=aiQueryUser

syntax match aiQueryCodeFence /```.*$/ contained containedin=aiQueryBot
syntax region aiQueryCode start=/^```/ end=/^```/ contained containedin=aiQueryBot keepend contains=aiQueryCodeFence

highlight default link aiQueryUser Function
highlight default aiQueryBot guifg=#D08770
highlight default aiQueryCodeFence guifg=#4C566A
highlight default aiQueryCode guifg=#A3BE8C

let b:current_syntax = "aiquery"
