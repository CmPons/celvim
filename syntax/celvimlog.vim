" Vim syntax file
" Language: Celvim Log
" Latest Revision: 9 January 2025

if exists("b:current_syntax")
  finish
endif

" Date and time (include '[' and ']')
syntax match celvimLogDateTime /\v\[\a{3}\s+\d{1,2}\s+\a{3}\s+\d{4}\s+\d{2}:\d{2}:\d{2}\]/

" Severity levels (make case insensitive)
syntax match celvimLogInfo /\c\v\-\s+info\s+\-/  
syntax match celvimLogWarn /\c\v\-\s+warn(ing)?\s+\-/
syntax match celvimLogDebug /\c\v\-\s+debug\s+\-/  
syntax match celvimLogTrace /\c\v\-\s+trace\s+\-/
syntax match celvimLogError /\c\v\-\s+error\s+\-/

" File paths and line numbers (allow dots in path)
syntax match celvimLogPath /\v\/\S+/
syntax match celvimLogLineNumber /\v\d+L/

" Byte size 
syntax match celvimLogSize /\v\d+B/

" Strings
syntax region celvimLogString start=/"/ end=/"/

" Lua error messages  
syntax match celvimLuaError /\v'.*'/

highlight default link celvimLogDateTime Boolean
highlight default link celvimLogError LspDiagnosticsSignError
highlight default link celvimLogWarn LspDiagnosticsSignWarning
highlight default link celvimLogInfo LspDiagnosticsSignInformation
highlight default link celvimLogTrace LspDiagnosticsSignHint  
highlight default link celvimLogDebug Comment
highlight default link celvimLogPath Directory
highlight default link celvimLogLineNumber LineNr
highlight default link celvimLogSize Number
highlight default link celvimLogString String
highlight default link celvimLuaError Error

let b:current_syntax = "celvimlog"
