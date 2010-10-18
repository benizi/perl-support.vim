"###############################################################################################
"
"       Filename:  perl-support.vim
"
"    Description:  perl-support.vim implements a Perl-IDE for Vim/gVim.  It is
"                  written to considerably speed up writing code in a consistent
"                  style.
"                  This is done by inserting complete statements, comments,
"                  idioms, code snippets, templates, comments and POD
"                  documentation.  Reading perldoc is integrated.  Syntax
"                  checking, running a script, starting a debugger and a
"                  profiler can be done by a keystroke.  
"                  There a many additional hints and options which can improve
"                  speed and comfort when writing Perl. Please read the
"                  documentation.
"
"  Configuration:  There are at least some personal details which should be configured 
"                  (see the files README.perlsupport and perlsupport.txt).
"
"         Author:  Dr.-Ing. Fritz Mehner <mehner@fh-swf.de>
"
"        Version:  see variable  g:Perl_Version  below 
"       Revision:  19.10.2005
"        Created:  09.07.2001
"        License:  GPL (GNU Public License)
"        Credits:  see perlsupport.txt
"
"------------------------------------------------------------------------------
" 
" Prevent duplicate loading: 
" 
if exists("g:Perl_Version") || &cp
 finish
endif
let g:Perl_Version= "2.7"
"        
"###############################################################################################
"
"  Global variables (with default values) which can be overridden.
"          
" Platform specific items:
" - root directory
" - characters that must be escaped for filenames
" 
let	s:MSWIN =		has("win16") || has("win32")     || has("win64") || 
							\ has("win95") || has("win32unix")
" 
if	s:MSWIN
	"
	let s:root_dir	  = $VIM.'\vimfiles\'
  let s:escfilename = ''
	"
else
	"
	let s:root_dir	  = $HOME.'/.vim/'
  let s:escfilename = ' \%#[]'
	"
endif
"
"  Key word completion is enabled by the filetype plugin 'perl.vim'
"  g:Perl_Dictionary_File  must be global
"          
if !exists("g:Perl_Dictionary_File")
	let g:Perl_Dictionary_File       = s:root_dir.'wordlists/perl.list'
endif
"
"  Modul global variables (with default values) which can be overridden.
"
let s:Perl_AuthorName              = ''
let s:Perl_AuthorRef               = ''
let s:Perl_Email                   = ''
let s:Perl_Company                 = ''
let s:Perl_Project                 = ''
let s:Perl_CopyrightHolder         = ''

let s:Perl_Root                    = '&Perl.'
let s:Perl_LoadMenus               = 'yes'
let s:Perl_CodeSnippets            = s:root_dir.'codesnippets-perl/'
let s:Perl_Template_Directory      = s:root_dir.'plugin/templates/'
let s:Perl_Template_File           = 'perl-file-header'
let s:Perl_Template_Module         = 'perl-module-header'
let s:Perl_Template_Frame          = 'perl-frame'
let s:Perl_Template_Function       = 'perl-function-description'
let s:Perl_MenuHeader              = 'yes'
let s:Perl_PerlModuleList          = s:root_dir.'plugin/perl-modules.list'
let s:Perl_PerlModuleListGenerator = s:root_dir.'plugin/pmdesc3.pl'
let s:Perl_OutputGvim              = "vim"
let s:Perl_XtermDefaults           = "-fa courier -fs 12 -geometry 80x24"
let s:Perl_Debugger                = "perl"
let s:Perl_ProfilerTimestamp       = "no"
let s:Perl_LineEndCommColDefault   = 49
let s:Perl_BraceOnNewLine          = "no"
"
"------------------------------------------------------------------------------
"
"  Look for global variables (if any), to override the defaults.
"  
function! Perl_CheckGlobal ( name )
	if exists('g:'.a:name)
		exe 'let s:'.a:name.'  = g:'.a:name
	endif
endfunction		" ---------- end of function  Perl_CheckGlobal  ----------
"
call Perl_CheckGlobal("Perl_AuthorName             ")
call Perl_CheckGlobal("Perl_AuthorRef              ")
call Perl_CheckGlobal("Perl_Email                  ")
call Perl_CheckGlobal("Perl_Company                ")
call Perl_CheckGlobal("Perl_Project                ")
call Perl_CheckGlobal("Perl_CopyrightHolder        ")
call Perl_CheckGlobal("Perl_Root                   ")
call Perl_CheckGlobal("Perl_LoadMenus              ")
call Perl_CheckGlobal("Perl_CodeSnippets           ")
call Perl_CheckGlobal("Perl_Template_Directory     ")
call Perl_CheckGlobal("Perl_Template_File          ")
call Perl_CheckGlobal("Perl_Template_Module        ")
call Perl_CheckGlobal("Perl_Template_Frame         ")
call Perl_CheckGlobal("Perl_Template_Function      ")
call Perl_CheckGlobal("Perl_MenuHeader             ")
call Perl_CheckGlobal("Perl_PerlModuleList         ")
call Perl_CheckGlobal("Perl_PerlModuleListGenerator")
call Perl_CheckGlobal("Perl_OutputGvim             ")
call Perl_CheckGlobal("Perl_XtermDefaults          ")
call Perl_CheckGlobal("Perl_Debugger               ")
call Perl_CheckGlobal("Perl_ProfilerTimestamp      ")
call Perl_CheckGlobal("Perl_LineEndCommColDefault  ")
call Perl_CheckGlobal("Perl_BraceOnNewLine         ")
"
"------------------------------------------------------------------------------
"  Perl Menu Initialization
"------------------------------------------------------------------------------
"
let	s:Perl_POD_cut ='<CR>=pod  <CR><CR><CR><CR>=cut  #  back to Perl<CR>'
let	s:Perl_POD_for ='<CR>=for  <CR><CR>=cut  #  back to Perl<CR>'
let	s:Perl_POD_List='<CR>=over 2<CR><CR>=item *<CR><CR><CR><CR>=item *<CR><CR><CR><CR>=back  #  back to Perl<CR><CR>'
let	s:Perl_POD_html='<CR>=begin  html<CR><CR><CR><CR>=end    html  #  back to Perl<CR>'
let	s:Perl_POD_man ='<CR>=begin  man<CR><CR><CR><CR>=end    man  #  back to Perl<CR>'
let	s:Perl_POD_text='<CR>=begin  text<CR><CR><CR><CR>=end    text  #  back to Perl<CR>'
"
" set default geometry if not specified 
" 
if match( s:Perl_XtermDefaults, "-geometry\\s\\+\\d\\+x\\d\\+" ) < 0
	let s:Perl_XtermDefaults	= s:Perl_XtermDefaults." -geometry 80x24"
endif
"
" Flags for perldoc
"
if has("gui_running")
	let s:Perl_perldoc_flags	= ""
else
	" Display docs using plain text converter.
	let s:Perl_perldoc_flags	= "-otext"
endif
"
function!	Perl_InitMenu ()
	"
	if has("gui_running")

		if s:Perl_Root != ""
			if s:Perl_MenuHeader == "yes"
				exe "amenu ".s:Perl_Root.'<Tab>Perl     <Esc>'
				exe "amenu ".s:Perl_Root.'-Sep0-        :'
			endif
		endif
		"
		"---------- Comments-Menu ----------------------------------------------------------------------
		"
		if s:Perl_MenuHeader == "yes"
			exe "amenu ".s:Perl_Root.'&Comments.Comments<Tab>Perl     <Esc>'
			exe "amenu ".s:Perl_Root.'&Comments.-Sep0-        :'
		endif

		exe "amenu           ".s:Perl_Root.'&Comments.&Line\ End\ Comm\.        <Esc><Esc>:call Perl_LineEndComment()<CR>A'
		exe "vmenu <silent>  ".s:Perl_Root.'&Comments.&Line\ End\ Comm\.        <Esc><Esc>:call Perl_MultiLineEndComments()<CR>A'
		exe "amenu <silent>  ".s:Perl_Root.'&Comments.&Set\ End\ Comm\.\ Col\.  <Esc><Esc>:call Perl_GetLineEndCommCol()<CR>'
		exe "amenu <silent>  ".s:Perl_Root.'&Comments.&Frame\ Comm\.            <Esc><Esc>:call Perl_CommentTemplates("frame")<CR>'
		exe "amenu <silent>  ".s:Perl_Root.'&Comments.F&unction\ Descr\.        <Esc><Esc>:call Perl_CommentTemplates("function")<CR>'
		exe "amenu <silent>  ".s:Perl_Root.'&Comments.File\ &Header\ (\.pl)     <Esc><Esc>:call Perl_CommentTemplates("header")<CR>'
		exe "amenu <silent>  ".s:Perl_Root.'&Comments.File\ Header\ (\.&pm)     <Esc><Esc>:call Perl_CommentTemplates("module")<CR>'

		exe "amenu ".s:Perl_Root.'&Comments.-SEP1-                     :'
		"
		exe "amenu <silent>  ".s:Perl_Root."&Comments.&code->comment       <Esc><Esc>:s/^/#/<CR><Esc>:nohlsearch<CR>"
		exe "vmenu <silent>  ".s:Perl_Root."&Comments.&code->comment       <Esc><Esc>:'<,'>s/^/#/<CR><Esc>:nohlsearch<CR>"
		exe "amenu <silent>  ".s:Perl_Root."&Comments.c&omment->code       <Esc><Esc>:s/^\\(\\s*\\)#/\\1/<CR><Esc>:nohlsearch<CR>"
		exe "vmenu <silent>  ".s:Perl_Root."&Comments.c&omment->code       <Esc><Esc>:'<,'>s/^\\(\\s*\\)#/\\1/<CR><Esc>:nohlsearch<CR>"
		"
		exe "amenu ".s:Perl_Root.'&Comments.-SEP2-               :'
		"
		exe " menu ".s:Perl_Root.'&Comments.&Date                i<C-R>=strftime("%x")<CR>'
		exe "imenu ".s:Perl_Root.'&Comments.&Date                 <C-R>=strftime("%x")<CR>'
		exe " menu ".s:Perl_Root.'&Comments.Date\ &Time          i<C-R>=strftime("%x %X %Z")<CR>'
		exe "imenu ".s:Perl_Root.'&Comments.Date\ &Time           <C-R>=strftime("%x %X %Z")<CR>'



		exe "amenu ".s:Perl_Root.'&Comments.-SEP3-                     :'
		"
		"--------- submenu : KEYWORD -------------------------------------------------------------
		"
		if s:Perl_MenuHeader == "yes"
			exe "amenu ".s:Perl_Root.'&Comments.#:&KEYWORD\:.Comments-1<Tab>Perl   <Esc>'
			exe "amenu ".s:Perl_Root.'&Comments.#:&KEYWORD\:.-Sep0-      :'
		endif
		"
		exe "amenu ".s:Perl_Root.'&Comments.#:&KEYWORD\:.&BUG          <Esc><Esc>$<Esc>:call Perl_CommentClassified("BUG")       <CR>kJA'
		exe "amenu ".s:Perl_Root.'&Comments.#:&KEYWORD\:.&TODO         <Esc><Esc>$<Esc>:call Perl_CommentClassified("TODO")      <CR>kJA'
		exe "amenu ".s:Perl_Root.'&Comments.#:&KEYWORD\:.T&RICKY       <Esc><Esc>$<Esc>:call Perl_CommentClassified("TRICKY")    <CR>kJA'
		exe "amenu ".s:Perl_Root.'&Comments.#:&KEYWORD\:.&WARNING      <Esc><Esc>$<Esc>:call Perl_CommentClassified("WARNING")   <CR>kJA'
		exe "amenu ".s:Perl_Root.'&Comments.#:&KEYWORD\:.W&ORKAROUND   <Esc><Esc>$<Esc>:call Perl_CommentClassified("WORKAROUND")<CR>kJA'
		exe "amenu ".s:Perl_Root.'&Comments.#:&KEYWORD\:.&new\ keyword <Esc><Esc>$<Esc>:call Perl_CommentClassified("")          <CR>kJf:a'
		"
		"
		"----- Submenu :  Tags  ----------------------------------------------------------
		"
		if s:Perl_MenuHeader == "yes"
			exe "amenu ".s:Perl_Root.'&Comments.Ta&gs\ (plugin).Comments-2<Tab>Perl   <Esc>'
			exe "amenu ".s:Perl_Root.'&Comments.Ta&gs\ (plugin).-Sep0-      :'
		endif
		"
		exe "amenu  ".s:Perl_Root.'&Comments.Ta&gs\ (plugin).&AUTHOR           a'.s:Perl_AuthorName."<Esc>"
		exe "amenu  ".s:Perl_Root.'&Comments.Ta&gs\ (plugin).AUTHOR&REF        a'.s:Perl_AuthorRef."<Esc>"
		exe "amenu  ".s:Perl_Root.'&Comments.Ta&gs\ (plugin).&COMPANY          a'.s:Perl_Company."<Esc>"
		exe "amenu  ".s:Perl_Root.'&Comments.Ta&gs\ (plugin).C&OPYRIGHTHOLDER  a'.s:Perl_CopyrightHolder."<Esc>"
		exe "amenu  ".s:Perl_Root.'&Comments.Ta&gs\ (plugin).&EMAIL            a'.s:Perl_Email."<Esc>"
		exe "amenu  ".s:Perl_Root.'&Comments.Ta&gs\ (plugin).&PROJECT          a'.s:Perl_Project."<Esc>"

		exe "imenu  ".s:Perl_Root.'&Comments.Ta&gs\ (plugin).&AUTHOR           <Esc>a'.s:Perl_AuthorName
		exe "imenu  ".s:Perl_Root.'&Comments.Ta&gs\ (plugin).AUTHOR&REF        <Esc>a'.s:Perl_AuthorRef
		exe "imenu  ".s:Perl_Root.'&Comments.Ta&gs\ (plugin).&COMPANY          <Esc>a'.s:Perl_Company
		exe "imenu  ".s:Perl_Root.'&Comments.Ta&gs\ (plugin).C&OPYRIGHTHOLDER  <Esc>a'.s:Perl_CopyrightHolder
		exe "imenu  ".s:Perl_Root.'&Comments.Ta&gs\ (plugin).&EMAIL            <Esc>a'.s:Perl_Email
		exe "imenu  ".s:Perl_Root.'&Comments.Ta&gs\ (plugin).&PROJECT          <Esc>a'.s:Perl_Project
		"
		"
		exe "amenu <silent>  ".s:Perl_Root.'&Comments.&vim\ modeline             <Esc><Esc>:call Perl_CommentVimModeline()<CR>'

		"---------- Statements-Menu ----------------------------------------------------------------------

		if s:Perl_MenuHeader == "yes"
			exe "amenu ".s:Perl_Root.'St&atements.Statements<Tab>Perl     <Esc>'
			exe "amenu ".s:Perl_Root.'St&atements.-Sep0-        :'
		endif
		"
		if s:Perl_BraceOnNewLine  == "no"
			exe "amenu ".s:Perl_Root.'St&atements.&do\ \{\ \}\ while               <Esc><Esc>:call Perl_DoWhile("a")<CR><Esc>3jf(la'
			exe "amenu ".s:Perl_Root.'St&atements.&for\ \{\ \}                     <Esc><Esc>ofor ( ; ;  ) {<CR>}<Esc>kf;i'
			exe "amenu ".s:Perl_Root.'St&atements.f&oreach\ \{\ \}                 <Esc><Esc>oforeach  (  ) {<CR>}<Tab><Tab><Tab><Tab># -----  end foreach  -----<Esc>kF(hi'
			exe "amenu ".s:Perl_Root.'St&atements.&if\ \{\ \}		                   <Esc><Esc>oif (  ) {<CR>}<Esc>kf(la'
			exe "amenu ".s:Perl_Root.'St&atements.if\ \{\ \}\ &else\ \{\ \}        <Esc><Esc>oif (  ) {<CR>}<CR>else {<CR>}<Esc>3kf(la'
			exe "amenu ".s:Perl_Root.'St&atements.&unless\ \{\ \}                  <Esc><Esc>ounless (  ) {<CR>}<Esc>kf(la'
			exe "amenu ".s:Perl_Root.'St&atements.u&nless\ \{\ \}\ else\ \{\ \}    <Esc><Esc>ounless (  ) {<CR>}<CR>else {<CR>}<Esc>3kf(la'
			exe "amenu ".s:Perl_Root.'St&atements.un&til\ \{\ \}                   <Esc><Esc>ountil (  ) {<CR>}<Esc>kf(la'
			exe "amenu ".s:Perl_Root.'St&atements.&while\ \{\ \}                   <Esc><Esc>owhile (  ) {<CR>}<Tab><Tab><Tab><Tab># -----  end while  -----<Esc>kF(la'
			exe "amenu ".s:Perl_Root.'St&atements.&\{\ \}                          <Esc><Esc>o{<CR>}<Esc>O'
			"
			exe "vmenu ".s:Perl_Root.'St&atements.&do\ \{\ \}\ while               <Esc><Esc>:call Perl_DoWhile("v")<CR><Esc>f(la'
			exe "vmenu ".s:Perl_Root."St&atements.&for\\ \{\\ \}                   DOfor ( ; ;  ) {<CR>}<Esc>Pk<Esc>:exe \"normal =\".(line(\"'>\")-line(\".\")-1).\"+\"<CR>f;i"
			exe "vmenu ".s:Perl_Root."St&atements.f&oreach\\ \{\\ \}               DOforeach  (  ) {<CR>}<Tab><Tab><Tab><Tab># -----  end foreach  -----<Esc>Pk<Esc>:exe \"normal =\".(line(\"'>\")-line(\".\")-1).\"+\"<CR>f(hi"
			exe "vmenu ".s:Perl_Root."St&atements.&if\\ \{\\ \}		                 DOif (  ) {<CR>}<Esc>Pk<Esc>:exe \"normal =\".(line(\"'>\")-line(\".\")-1).\"+\"<CR>f(la"
			exe "vmenu ".s:Perl_Root."St&atements.if\\ \{\\ \}\\ &else\\ \{\\ \}      DOif (  ) {<CR>}<CR>else {<CR>}<Esc>2kPk<Esc>:exe \"normal =\".(line(\"'>\")-line(\".\")-1).\"+\"<CR>f(la"
			exe "vmenu ".s:Perl_Root."St&atements.&unless\\ \{\\ \}                   DOunless (  ) {<CR>}<Esc>Pk<Esc>:exe \"normal =\".(line(\"'>\")-line(\".\")-1).\"+\"<CR>f(la"
			exe "vmenu ".s:Perl_Root."St&atements.u&nless\\ \{\\ \}\\ else\\ \{\\ \}  DOunless (  ) {<CR>}<CR>else {<CR>}<Esc>2kPk<Esc>:exe \"normal =\".(line(\"'>\")-line(\".\")-1).\"+\"<CR>f(la"
			exe "vmenu ".s:Perl_Root."St&atements.un&til\\ \{\\ \}                    DOuntil (  ) {<CR>}<Esc>Pk<Esc>:exe \"normal =\".(line(\"'>\")-line(\".\")-1).\"+\"<CR>f(la"
			exe "vmenu ".s:Perl_Root."St&atements.&while\\ \{\\ \}                    DOwhile (  ) {<CR>}<Tab><Tab><Tab><Tab># -----  end while  -----<Esc>Pk<Esc>:exe \"normal =\".(line(\"'>\")-line(\".\")-1).\"+\"<CR>f(la"
			exe "vmenu ".s:Perl_Root."St&atements.&\\{\\ \\}                          DO{<CR>}<Esc>Pk<Esc>:exe \"normal =\".(line(\"'>\")-line(\".\")-1).\"+\"<CR>"
		"
		else
			exe "amenu ".s:Perl_Root.'St&atements.&do\ \{\ \}\ while               <Esc><Esc>:call Perl_DoWhile("a")<CR><Esc>4jf(la'
			exe "amenu ".s:Perl_Root.'St&atements.&for\ \{\ \}                     <Esc><Esc>ofor ( ; ;  )<CR>{<CR>}<Esc>2kf;i'
			exe "amenu ".s:Perl_Root.'St&atements.f&oreach\ \{\ \}                 <Esc><Esc>oforeach  (  )<CR>{<CR>}<Tab><Tab><Tab><Tab># -----  end foreach  -----<Esc>2kF(hi'
			exe "amenu ".s:Perl_Root.'St&atements.&if\ \{\ \}		                   <Esc><Esc>oif (  )<CR>{<CR>}<Esc>2kf(la'
			exe "amenu ".s:Perl_Root.'St&atements.if\ \{\ \}\ &else\ \{\ \}        <Esc><Esc>oif (  )<CR>{<CR>}<CR>else<CR>{<CR>}<Esc>5kf(la'
			exe "amenu ".s:Perl_Root.'St&atements.&unless\ \{\ \}                  <Esc><Esc>ounless (  )<CR>{<CR>}<Esc>2kf(la'
			exe "amenu ".s:Perl_Root.'St&atements.u&nless\ \{\ \}\ else\ \{\ \}    <Esc><Esc>ounless (  )<CR>{<CR>}<CR>else<CR>{<CR>}<Esc>5kf(la'
			exe "amenu ".s:Perl_Root.'St&atements.un&til\ \{\ \}                   <Esc><Esc>ountil (  )<CR>{<CR>}<Esc>2kf(la'
			exe "amenu ".s:Perl_Root.'St&atements.&while\ \{\ \}                   <Esc><Esc>owhile (  )<CR>{<CR>}<Tab><Tab><Tab><Tab># -----  end while  -----<Esc>2kF(la'
			exe "amenu ".s:Perl_Root.'St&atements.&\{\ \}                          <Esc><Esc>o{<CR>}<Esc>O'
			"
			exe "vmenu ".s:Perl_Root.'St&atements.&do\ \{\ \}\ while               <Esc><Esc>:call Perl_DoWhile("v")<CR><Esc>f(la'
			exe "vmenu ".s:Perl_Root."St&atements.&for\\ \{\\ \}                   DOfor ( ; ;  )<CR>{<CR>}<Esc>P2k<Esc>:exe \"normal =\".(line(\"'>\")-line(\".\")-1).\"+\"<CR>f;i"
			exe "vmenu ".s:Perl_Root."St&atements.f&oreach\\ \{\\ \}               DOforeach  (  )<CR>{<CR>}<Tab><Tab><Tab><Tab># -----  end foreach  -----<Esc>P2k<Esc>:exe \"normal =\".(line(\"'>\")-line(\".\")-1).\"+\"<CR>f(hi"
			exe "vmenu ".s:Perl_Root."St&atements.&if\\ \{\\ \}		                 DOif (  )<CR>{<CR>}<Esc>P2k<Esc>:exe \"normal =\".(line(\"'>\")-line(\".\")-1).\"+\"<CR>f(la"
			exe "vmenu ".s:Perl_Root."St&atements.if\\ \{\\ \}\\ &else\\ \{\\ \}      DOif (  )<CR>{<CR>}<CR>else<CR>{<CR>}<Esc>3kP2k<Esc>:exe \"normal =\".(line(\"'>\")-line(\".\")-1).\"+\"<CR>f(la"
			exe "vmenu ".s:Perl_Root."St&atements.&unless\\ \{\\ \}                   DOunless (  )<CR>{<CR>}<Esc>P2k<Esc>:exe \"normal =\".(line(\"'>\")-line(\".\")-1).\"+\"<CR>f(la"
			exe "vmenu ".s:Perl_Root."St&atements.u&nless\\ \{\\ \}\\ else\\ \{\\ \}  DOunless (  )<CR>{<CR>}<CR>else<CR>{<CR>}<Esc>3kP2k<Esc>:exe \"normal =\".(line(\"'>\")-line(\".\")-1).\"+\"<CR>f(la"
			exe "vmenu ".s:Perl_Root."St&atements.un&til\\ \{\\ \}                    DOuntil (  )<CR>{<CR>}<Esc>P2k<Esc>:exe \"normal =\".(line(\"'>\")-line(\".\")-1).\"+\"<CR>f(la"
			exe "vmenu ".s:Perl_Root."St&atements.&while\\ \{\\ \}                    DOwhile (  )<CR>{<CR>}<Tab><Tab><Tab><Tab># -----  end while  -----<Esc>P2k<Esc>:exe \"normal =\".(line(\"'>\")-line(\".\")-1).\"+\"<CR>f(la"
			exe "vmenu ".s:Perl_Root."St&atements.&\\{\\ \\}                          DO{<CR>}<Esc>Pk<Esc>:exe \"normal =\".(line(\"'>\")-line(\".\")-1).\"+\"<CR>"
		endif
		"
		" The menu entries for code snippet support will not appear if the following string is empty 
		if s:Perl_CodeSnippets != ""
			exe "imenu ".s:Perl_Root.'St&atements.-SEP6-                      			:'
			exe "amenu <silent>  ".s:Perl_Root.'St&atements.&read\ code\ snippet    <C-C>:call Perl_CodeSnippet("r")<CR>'
			exe "amenu <silent>  ".s:Perl_Root.'St&atements.&write\ code\ snippet   <C-C>:call Perl_CodeSnippet("w")<CR>'
			exe "vmenu <silent>  ".s:Perl_Root.'St&atements.&write\ code\ snippet   <C-C>:call Perl_CodeSnippet("wv")<CR>'
			exe "amenu <silent>  ".s:Perl_Root.'St&atements.e&dit\ code\ snippet    <C-C>:call Perl_CodeSnippet("e")<CR>'
		endif
		"
		"---------- submenu : idioms -------------------------------------------------------------
		"
		if s:Perl_MenuHeader == "yes"
			exe "amenu ".s:Perl_Root.'I&dioms.Idioms<Tab>Perl    <Esc>'
			exe "amenu ".s:Perl_Root.'I&dioms.-Sep0-       :'
		endif
		"
		exe "amenu ".s:Perl_Root.'I&dioms.&my\ $;                       <Esc><Esc>omy<Tab>$;<Esc>i'
		exe "amenu ".s:Perl_Root.'I&dioms.m&y\ $\ =\ ;                  <Esc><Esc>omy<Tab>$<Tab>= ;<Esc>F$a'
		exe "amenu ".s:Perl_Root.'I&dioms.my\ (\ $&,\ $\ );             <Esc><Esc>omy<Tab>( $, $ );<Esc>2F$a'
		exe "amenu ".s:Perl_Root.'I&dioms.-SEP1-                        :'
		exe "amenu ".s:Perl_Root.'I&dioms.(&1)\ my\ @;                  <Esc><Esc>omy<Tab>@;<Esc>i'
		exe "amenu ".s:Perl_Root.'I&dioms.(&2)\ my\ @\ =\ (,,);         <Esc><Esc>omy<Tab>@<Tab>= ( , ,  );<Esc>F@a'
		exe "amenu ".s:Perl_Root.'I&dioms.-SEP2-                        :'
		exe "amenu ".s:Perl_Root.'I&dioms.(&3)\ my\ %;                  <Esc><Esc>omy<Tab>%;<Esc>i'
		exe "amenu ".s:Perl_Root.'I&dioms.(&4)\ my\ %\ =\ (=>,);        <Esc><Esc>omy<Tab>%<Tab>= <CR>(<CR>=> ,<CR>=> ,<CR>);<Esc>k0i<Tab><Tab><Esc>k0i<Tab><Tab><Esc>2kf%a'
		exe "amenu ".s:Perl_Root.'I&dioms.(&5)\ my\ $rgx_\ =\ q//;      <Esc><Esc>omy<Tab>$rgx_<Tab>= q//;<Esc>F_a'
		exe "amenu ".s:Perl_Root.'I&dioms.(&6)\ my\ $rgx_\ =\ qr//;     <Esc><Esc>omy<Tab>$rgx_<Tab>= qr//;<Esc>F_a'
		exe "amenu ".s:Perl_Root.'I&dioms.-SEP3-                        :'
		exe " menu ".s:Perl_Root.'I&dioms.(&7)\ $\ =~\ m//              <Esc>a$ =~ m//<Esc>F$a'
		exe " menu ".s:Perl_Root.'I&dioms.(&8)\ $\ =~\ s///             <Esc>a$ =~ s///<Esc>F$a'
		exe " menu ".s:Perl_Root.'I&dioms.(&9)\ $\ =~\ tr///            <Esc>a$ =~ tr///<Esc>F$a'
		exe "imenu ".s:Perl_Root.'I&dioms.(&7)\ $\ =~\ m//              $ =~ m//<Esc>F$a'
		exe "imenu ".s:Perl_Root.'I&dioms.(&8)\ $\ =~\ s///             $ =~ s///<Esc>F$a'
		exe "imenu ".s:Perl_Root.'I&dioms.(&9)\ $\ =~\ tr///            $ =~ tr///<Esc>F$a'
		exe " menu ".s:Perl_Root.'I&dioms.-SEP4-                        :'
		exe "amenu ".s:Perl_Root.'I&dioms.&subroutine                   <Esc><Esc>:call Perl_Subroutine("a")<CR>A'
		exe "vmenu ".s:Perl_Root.'I&dioms.&subroutine                   <Esc><Esc>:call Perl_Subroutine("v")<CR>f(a'
		exe " menu ".s:Perl_Root.'I&dioms.&print\ \"\.\.\.\\n\";        <Esc>aprint "\n";<ESC>3hi'
		exe " menu ".s:Perl_Root.'I&dioms.print&f\ (\"\.\.\.\\n\");     <Esc>aprintf ("\n");<ESC>4hi'
		exe "imenu ".s:Perl_Root.'I&dioms.&print\ \"\.\.\.\\n\";        print "\n";<ESC>3hi'
		exe "imenu ".s:Perl_Root.'I&dioms.print&f\ (\"\.\.\.\\n\");     printf ("\n");<ESC>4hi'
		exe "amenu ".s:Perl_Root.'I&dioms.open\ &input\ file            <Esc><Esc>:call Perl_OpenInputFile()<CR>a'
		exe "amenu ".s:Perl_Root.'I&dioms.open\ &output\ file           <Esc><Esc>:call Perl_OpenOutputFile()<CR>a'
		exe "amenu ".s:Perl_Root.'I&dioms.open\ pip&e                   <Esc><Esc>:call Perl_OpenPipe()<CR>a'
		exe "amenu ".s:Perl_Root.'I&dioms.-SEP5-                        :'
		exe " menu ".s:Perl_Root.'I&dioms.<STDIN>                       <Esc>a<STDIN>'
		exe " menu ".s:Perl_Root.'I&dioms.<STDOUT>                      <Esc>a<STDOUT>'
		exe " menu ".s:Perl_Root.'I&dioms.<STDERR>                      <Esc>a<STDERR>'
		exe "imenu ".s:Perl_Root.'I&dioms.<STDIN>                       <STDIN>'
		exe "imenu ".s:Perl_Root.'I&dioms.<STDOUT>                      <STDOUT>'
		exe "imenu ".s:Perl_Root.'I&dioms.<STDERR>                      <STDERR>'
		exe "imenu ".s:Perl_Root.'I&dioms.-SEP7-                        :'
		"
		"---------- submenu : Regular Expression Suport  -----------------------------------------
		"
		if s:Perl_MenuHeader == "yes"
			exe "amenu ".s:Perl_Root.'Rege&x.Regex<Tab>Perl      <Esc>'
			exe "amenu ".s:Perl_Root.'Rege&x.-Sep0-         :'
		endif
		"
		"
		"---------- subsubmenu : Regular Expression Suport  -----------------------------------------
		"
		if s:Perl_MenuHeader == "yes"
			exe "amenu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.Regex-1<Tab>Perl      <Esc>'
			exe "amenu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.-Sep0-         :'
		endif
		"
		exe "amenu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.&comment<Tab>(?#\ \.\.\.\ )                 			<Esc><Esc>a(?#)<Esc>i'
		exe "amenu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.cl&uster\ only\ paren\.<Tab>(?:\ \.\.\.\ )        <Esc><Esc>a(?:)<Esc>i'
		exe "amenu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.pattern\ &modifier<Tab>(?imsx-imsx)               <Esc><Esc>a(?)<Esc>i'
		exe "amenu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.e&xecute\ code<Tab>(?\{\ \.\.\.\ \})            	<Esc><Esc>a(?{})<Esc>hi'
		exe "amenu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.match\ &regex\ from\ code<Tab>(??\{\ \.\.\.\ \})	<Esc><Esc>a(??{})<Esc>F{a'
		exe "amenu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.match-if-&then<Tab>(?(\.\.)\.\.)       				  	<Esc><Esc>a(?())<Esc>F(a'
		exe "amenu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.match-if-t&hen-else<Tab>(?(\.\.)\.\.\|\.\.)     	<Esc><Esc>a(?()\|))<Esc>F(a'
		exe " menu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.-SEP11-																						:'
		exe "amenu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.look&ahead\ succeeds<Tab>(?=\ \.\.\.\ )     			<Esc><Esc>a(?=)<Esc>i'
		exe "amenu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.looka&head\ fails<Tab>(?!\ \.\.\.\ )         			<Esc><Esc>a(?!)<Esc>i'
		exe "amenu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.look&behind\ succeeds<Tab>(?<=\ \.\.\.\ )      		<Esc><Esc>a(?<=)<Esc>i'
		exe "amenu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.lookb&ehind\ fails<Tab>(?<!\ \.\.\.\ )         		<Esc><Esc>a(?<!)<Esc>i'

		exe "vmenu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.&comment<Tab>(?#\ \.\.\.\ )                 			di(?#)<Esc>P2l'
		exe "vmenu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.cl&uster\ only\ paren\.<Tab>(?:\ \.\.\.\ )        di(?:)<Esc>P2l'
		exe "vmenu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.pattern\ &modifier<Tab>(?imsx-imsx)               di(?)<Esc>P2l'
		exe "vmenu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.e&xecute\ code<Tab>(?\{\ \.\.\.\ \})            	di(?{})<Esc>hP3l'
		exe "vmenu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.match\ &regex\ from\ code<Tab>(??\{\ \.\.\.\ \})	di(??{})<Esc>hP3l'
		exe "vmenu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.match-if-&then<Tab>(?(\.\.)\.\.)       				  	di(?())<Esc>F(pla'
		exe "vmenu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.match-if-t&hen-else<Tab>(?(\.\.)\.\.\|\.\.)     	di(?()\|)<Esc>F(pla'
		exe "vmenu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.-SEP11-																						:'
		exe "vmenu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.look&ahead\ succeeds<Tab>(?=\ \.\.\.\ )     			di(?=)<Esc>P2l'
		exe "vmenu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.looka&head\ fails<Tab>(?!\ \.\.\.\ )         			di(?!)<Esc>P2l'
		exe "vmenu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.look&behind\ succeeds<Tab>(?<=\ \.\.\.\ )      		di(?<=)<Esc>P2l'
		exe "vmenu ".s:Perl_Root.'Rege&x.e&xtended\ Regex.lookb&ehind\ fails<Tab>(?<!\ \.\.\.\ )         		di(?<!)<Esc>P2l'
		exe " menu ".s:Perl_Root.'Rege&x.-SEP2-																:'
		"
		exe "amenu ".s:Perl_Root.'Rege&x.&Grouping<Tab>(\ )       				<Esc><Esc><Esc>a()<Esc>i'
		exe "vmenu ".s:Perl_Root.'Rege&x.&Grouping<Tab>(\ )       				di()<Esc>Pla'
		exe "amenu ".s:Perl_Root.'Rege&x.&Alternation<Tab>(\ \|\ )   			<Esc><Esc>a(\|)<Esc>hi'
		exe "vmenu ".s:Perl_Root.'Rege&x.&Alternation<Tab>(\ \|\ )  		 	di(\|)<Esc>hPla'
		exe "amenu ".s:Perl_Root.'Rege&x.Char\.\ &class<Tab>[\ ]       		<Esc><Esc>a[]<Esc>i'
		exe "vmenu ".s:Perl_Root.'Rege&x.Char\.\ &class<Tab>[\ ]       		di[]<Esc>Pla'
		exe "amenu ".s:Perl_Root.'Rege&x.C&ount<Tab>{\ }       			      <Esc><Esc>a{}<Esc>i'
		exe "vmenu ".s:Perl_Root.'Rege&x.C&ount<Tab>{\ }       						di{}<Esc>Pla'
		exe "amenu ".s:Perl_Root.'Rege&x.Co&unt\ (at\ least)<Tab>{\ ,\ }  <Esc><Esc>a{,}<Esc>hi'
		exe "vmenu ".s:Perl_Root.'Rege&x.Co&unt\ (at\ least)<Tab>{\ ,\ }  di{,}<Esc>hPla'
		"
		exe " menu ".s:Perl_Root.'Rege&x.-SEP0-															:'
		"
		exe " menu ".s:Perl_Root.'Rege&x.Word\ &boundary<Tab>\\b              <Esc>a\b'
		exe "imenu ".s:Perl_Root.'Rege&x.Word\ &boundary<Tab>\\b     			 		\b'
		exe " menu ".s:Perl_Root.'Rege&x.&Digit<Tab>\\d                       <Esc>a\d'
		exe "imenu ".s:Perl_Root.'Rege&x.&Digit<Tab>\\d 				              \d'
		exe " menu ".s:Perl_Root.'Rege&x.White&space<Tab>\\s                  <Esc>a\s'
		exe "imenu ".s:Perl_Root.'Rege&x.White&space<Tab>\\s				 			 		\s'
		exe " menu ".s:Perl_Root.'Rege&x.&Word\ character<Tab>\\w             <Esc>a\w'
		exe "imenu ".s:Perl_Root.'Rege&x.&Word\ character<Tab>\\w      		 		\w'
		exe " menu ".s:Perl_Root.'Rege&x.-SEP1-											 			 		:'
		exe " menu ".s:Perl_Root.'Rege&x.Non-(word\ bound\.)\ (&1)<Tab>\\B    <Esc>a\B'
		exe "imenu ".s:Perl_Root.'Rege&x.Non-(word\ bound\.)\ (&1)<Tab>\\B    \B'
		exe " menu ".s:Perl_Root.'Rege&x.Non-digit\ (&2)<Tab>\\D  						<Esc>a\D'
		exe "imenu ".s:Perl_Root.'Rege&x.Non-digit\ (&2)<Tab>\\D 							\D'
		exe " menu ".s:Perl_Root.'Rege&x.Non-whitespace\ (&3)<Tab>\\S    			<Esc>a\S'
		exe "imenu ".s:Perl_Root.'Rege&x.Non-whitespace\ (&3)<Tab>\\S 				\S'
		exe " menu ".s:Perl_Root.'Rege&x.Non-\"word\"\ char\.\ (&4)<Tab>\\W   <Esc>a\W'
		exe "imenu ".s:Perl_Root.'Rege&x.Non-\"word\"\ char\.\ (&4)<Tab>\\W   \W'
		"
		"---------- submenu : POSIX character classes --------------------------------------------
		"
		if s:Perl_MenuHeader == "yes"
			exe "amenu ".s:Perl_Root.'CharC&ls.CharCls<Tab>Perl   <Esc>'
			exe "amenu ".s:Perl_Root.'CharC&ls.-Sep0-      :'
		endif
		"
		exe " menu ".s:Perl_Root.'CharC&ls.[:&alnum:]		<Esc>a[:alnum:]'
		exe " menu ".s:Perl_Root.'CharC&ls.[:alp&ha:]		<Esc>a[:alpha:]'
		exe " menu ".s:Perl_Root.'CharC&ls.[:asc&ii:]		<Esc>a[:ascii:]'
		exe " menu ".s:Perl_Root.'CharC&ls.[:&cntrl:]		<Esc>a[:cntrl:]'
		exe " menu ".s:Perl_Root.'CharC&ls.[:&digit:]		<Esc>a[:digit:]'
		exe " menu ".s:Perl_Root.'CharC&ls.[:&graph:]		<Esc>a[:graph:]'
		exe " menu ".s:Perl_Root.'CharC&ls.[:&lower:]		<Esc>a[:lower:]'
		exe " menu ".s:Perl_Root.'CharC&ls.[:&print:]		<Esc>a[:print:]'
		exe " menu ".s:Perl_Root.'CharC&ls.[:pu&nct:]		<Esc>a[:punct:]'
		exe " menu ".s:Perl_Root.'CharC&ls.[:&space:]		<Esc>a[:space:]'
		exe " menu ".s:Perl_Root.'CharC&ls.[:&upper:]		<Esc>a[:upper:]'
		exe " menu ".s:Perl_Root.'CharC&ls.[:&word:]		<Esc>a[:word:]'
		exe " menu ".s:Perl_Root.'CharC&ls.[:&xdigit:]	<Esc>a[:xdigit:]'
		"
		exe "imenu ".s:Perl_Root.'CharC&ls.[:&alnum:]		[:alnum:]'
		exe "imenu ".s:Perl_Root.'CharC&ls.[:alp&ha:]		[:alpha:]'
		exe "imenu ".s:Perl_Root.'CharC&ls.[:asc&ii:]		[:ascii:]'
		exe "imenu ".s:Perl_Root.'CharC&ls.[:&cntrl:]		[:cntrl:]'
		exe "imenu ".s:Perl_Root.'CharC&ls.[:&digit:]		[:digit:]'
		exe "imenu ".s:Perl_Root.'CharC&ls.[:&graph:]		[:graph:]'
		exe "imenu ".s:Perl_Root.'CharC&ls.[:&lower:]		[:lower:]'
		exe "imenu ".s:Perl_Root.'CharC&ls.[:&print:]		[:print:]'
		exe "imenu ".s:Perl_Root.'CharC&ls.[:pu&nct:]		[:punct:]'
		exe "imenu ".s:Perl_Root.'CharC&ls.[:&space:]		[:space:]'
		exe "imenu ".s:Perl_Root.'CharC&ls.[:&upper:]		[:upper:]'
		exe "imenu ".s:Perl_Root.'CharC&ls.[:&word:]		[:word:]'
		exe "imenu ".s:Perl_Root.'CharC&ls.[:&xdigit:]	[:xdigit:]'
		"
		"
		"---------- File-Tests-Menu ----------------------------------------------------------------------
		"
		if s:Perl_MenuHeader == "yes"
			exe "amenu ".s:Perl_Root.'F&ile-Tests.File-Tests<Tab>Perl             <Esc>'
			exe "amenu ".s:Perl_Root.'F&ile-Tests.-Sep0-                          :'
		endif
		"
		exe " menu ".s:Perl_Root.'F&ile-Tests.exists<Tab>-e											<Esc>a-e <Esc>a'
		exe " menu ".s:Perl_Root.'F&ile-Tests.has\ zero\ size<Tab>-z						<Esc>a-z <Esc>a'
		exe " menu ".s:Perl_Root.'F&ile-Tests.has\ nonzero\ size<Tab>-s					<Esc>a-s <Esc>a'
		exe " menu ".s:Perl_Root.'F&ile-Tests.plain\ file<Tab>-f								<Esc>a-f <Esc>a'
		exe " menu ".s:Perl_Root.'F&ile-Tests.directory<Tab>-d									<Esc>a-d <Esc>a'
		exe " menu ".s:Perl_Root.'F&ile-Tests.symbolic\ link<Tab>-l							<Esc>a-l <Esc>a'
		exe " menu ".s:Perl_Root.'F&ile-Tests.named\ pipe<Tab>-p								<Esc>a-p <Esc>a'
		exe " menu ".s:Perl_Root.'F&ile-Tests.socket<Tab>-S											<Esc>a-S <Esc>a'
		exe " menu ".s:Perl_Root.'F&ile-Tests.block\ special\ file<Tab>-b				<Esc>a-b <Esc>a'
		exe " menu ".s:Perl_Root.'F&ile-Tests.character\ special\ file<Tab>-c		<Esc>a-c <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.exists<Tab>-e											-e <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.has\ zero\ size<Tab>-z						-z <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.has\ nonzero\ size<Tab>-s					-s <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.plain\ file<Tab>-f								-f <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.directory<Tab>-d									-d <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.symbolic\ link<Tab>-l							-l <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.named\ pipe<Tab>-p								-p <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.socket<Tab>-S											-S <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.block\ special\ file<Tab>-b				-b <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.character\ special\ file<Tab>-c		-c <Esc>a'
		"
		exe " menu ".s:Perl_Root.'F&ile-Tests.-SEP1-															:'
		"
		exe " menu ".s:Perl_Root.'F&ile-Tests.readable\ by\ eff\.\ UID/GID<Tab>-r			<Esc>a-r <Esc>a'
		exe " menu ".s:Perl_Root.'F&ile-Tests.writable\ by\ eff\.\ UID/GID<Tab>-w			<Esc>a-w <Esc>a'
		exe " menu ".s:Perl_Root.'F&ile-Tests.executable\ by\ eff\.\ UID/GID<Tab>-x		<Esc>a-x <Esc>a'
		exe " menu ".s:Perl_Root.'F&ile-Tests.owned\ by\ eff\.\ UID<Tab>-o						<Esc>a-o <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.readable\ by\ eff\.\ UID/GID<Tab>-r			-r <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.writable\ by\ eff\.\ UID/GID<Tab>-w			-w <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.executable\ by\ eff\.\ UID/GID<Tab>-x		-x <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.owned\ by\ eff\.\ UID<Tab>-o						-o <Esc>a'
		"
		exe " menu ".s:Perl_Root.'F&ile-Tests.-SEP2-													:'
		exe " menu ".s:Perl_Root.'F&ile-Tests.readable\ by\ real\ UID/GID<Tab>-R			<Esc>a-R <Esc>a'
		exe " menu ".s:Perl_Root.'F&ile-Tests.writable\ by\ real\ UID/GID<Tab>-W			<Esc>a-W <Esc>a'
		exe " menu ".s:Perl_Root.'F&ile-Tests.executable\ by\ real\ UID/GID<Tab>-X		<Esc>a-X <Esc>a'
		exe " menu ".s:Perl_Root.'F&ile-Tests.owned\ by\ real\ UID<Tab>-O							<Esc>a-O <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.readable\ by\ real\ UID/GID<Tab>-R			-R <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.writable\ by\ real\ UID/GID<Tab>-W			-W <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.executable\ by\ real\ UID/GID<Tab>-X		-X <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.owned\ by\ real\ UID<Tab>-O							-O <Esc>a'

		exe " menu ".s:Perl_Root.'F&ile-Tests.-SEP3-													:'
		exe " menu ".s:Perl_Root.'F&ile-Tests.setuid\ bit\ set<Tab>-u					<Esc>a-u <Esc>a'
		exe " menu ".s:Perl_Root.'F&ile-Tests.setgid\ bit\ set<Tab>-g					<Esc>a-g <Esc>a'
		exe " menu ".s:Perl_Root.'F&ile-Tests.sticky\ bit\ set<Tab>-k					<Esc>a-k <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.setuid\ bit\ set<Tab>-u					-u <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.setgid\ bit\ set<Tab>-g					-g <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.sticky\ bit\ set<Tab>-k					-k <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.-SEP4-													:'
		exe " menu ".s:Perl_Root.'F&ile-Tests.age\ since\ modification<Tab>-M				<Esc>a-M <Esc>a'
		exe " menu ".s:Perl_Root.'F&ile-Tests.age\ since\ last\ access<Tab>-A				<Esc>a-A <Esc>a'
		exe " menu ".s:Perl_Root.'F&ile-Tests.age\ since\ inode\ change<Tab>-C			<Esc>a-C <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.age\ since\ modification<Tab>-M				-M <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.age\ since\ last\ access<Tab>-A				-A <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.age\ since\ inode\ change<Tab>-C			-C <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.-SEP5-													:'
		exe " menu ".s:Perl_Root.'F&ile-Tests.text\ file<Tab>-T											<Esc>a-T <Esc>a'
		exe " menu ".s:Perl_Root.'F&ile-Tests.binary\ file<Tab>-B										<Esc>a-B <Esc>a'
		exe " menu ".s:Perl_Root.'F&ile-Tests.handle\ opened\ to\ a\ tty<Tab>-t			<Esc>a-t <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.text\ file<Tab>-T											-T <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.binary\ file<Tab>-B										-B <Esc>a'
		exe "imenu ".s:Perl_Root.'F&ile-Tests.handle\ opened\ to\ a\ tty<Tab>-t			-t <Esc>a'
		"
		"---------- Special-Variables -------------------------------------------------------------
		"
		if s:Perl_MenuHeader == "yes"
			exe "amenu ".s:Perl_Root.'Spec-&Var.Spec-Var<Tab>Perl      <Esc>'
			exe "amenu ".s:Perl_Root.'Spec-&Var.-Sep0-         :'
		endif
		"
		"-------- submenu errors -------------------------------------------------
		if s:Perl_MenuHeader == "yes"
			exe "amenu ".s:Perl_Root.'Spec-&Var.&errors.Spec-Var-1<Tab>Perl       <Esc>'
			exe "amenu ".s:Perl_Root.'Spec-&Var.&errors.-Sep0-              			:'
		endif
		exe " menu ".s:Perl_Root.'Spec-&Var.&errors.$CHILD_ERROR<Tab>$?					<Esc>a$CHILD_ERROR'
		exe " menu ".s:Perl_Root.'Spec-&Var.&errors.$ERRNO<Tab>$!            		<Esc>a$ERRNO'
		exe " menu ".s:Perl_Root.'Spec-&Var.&errors.$EVAL_ERROR<Tab>$@       		<Esc>a$EVAL_ERROR'
		exe " menu ".s:Perl_Root.'Spec-&Var.&errors.$EXTENDED_OS_ERROR<Tab>$^E	<Esc>a$EXTENDED_OS_ERROR'
"		exe " menu ".s:Perl_Root.'Spec-&Var.&errors.$OS_ERRNO         			<Esc>a$OS_ERRNO'
		exe " menu ".s:Perl_Root.'Spec-&Var.&errors.$WARNING<Tab>$^W          		<Esc>a$WARNING'
		exe "imenu ".s:Perl_Root.'Spec-&Var.&errors.$CHILD_ERROR<Tab>$?      			$CHILD_ERROR'
		exe "imenu ".s:Perl_Root.'Spec-&Var.&errors.$ERRNO<Tab>$!            			$ERRNO'
		exe "imenu ".s:Perl_Root.'Spec-&Var.&errors.$EVAL_ERROR<Tab>$@       			$EVAL_ERROR'
		exe "imenu ".s:Perl_Root.'Spec-&Var.&errors.$EXTENDED_OS_ERROR<Tab>$^E		$EXTENDED_OS_ERROR'
"		exe "imenu ".s:Perl_Root.'Spec-&Var.&errors.$OS_ERRNO<Tab>$         			$OS_ERRNO'
		exe "imenu ".s:Perl_Root.'Spec-&Var.&errors.$WARNING<Tab>$^W          		$WARNING'

		"-------- submenu files -------------------------------------------------
		if s:Perl_MenuHeader == "yes"
			exe "amenu ".s:Perl_Root.'Spec-&Var.&files.Spec-Var-2<Tab>Perl     <Esc>'
			exe "amenu ".s:Perl_Root.'Spec-&Var.&files.-Sep0-                  :'
		endif
		exe " menu ".s:Perl_Root.'Spec-&Var.&files.$AUTOFLUSH<Tab>$\|              <Esc>a$AUTOFLUSH'
		exe " menu ".s:Perl_Root.'Spec-&Var.&files.$OUTPUT_AUTOFLUSH<Tab>$\|       <Esc>a$OUTPUT_AUTOFLUSH'
		exe " menu ".s:Perl_Root.'Spec-&Var.&files.$FORMAT_LINES_LEFT<Tab>$-       <Esc>a$FORMAT_LINES_LEFT'
		exe " menu ".s:Perl_Root.'Spec-&Var.&files.$FORMAT_LINES_PER_PAGE<Tab>$=   <Esc>a$FORMAT_LINES_PER_PAGE'
		exe " menu ".s:Perl_Root.'Spec-&Var.&files.$FORMAT_NAME<Tab>$~             <Esc>a$FORMAT_NAME'
		exe " menu ".s:Perl_Root.'Spec-&Var.&files.$FORMAT_PAGE_NUMBER<Tab>$%      <Esc>a$FORMAT_PAGE_NUMBER'
		exe " menu ".s:Perl_Root.'Spec-&Var.&files.$FORMAT_TOP_NAME<Tab>$^         <Esc>a$FORMAT_TOP_NAME'
		exe "imenu ".s:Perl_Root.'Spec-&Var.&files.$AUTOFLUSH<Tab>$\|              $AUTOFLUSH'
		exe "imenu ".s:Perl_Root.'Spec-&Var.&files.$OUTPUT_AUTOFLUSH<Tab>$\|       $OUTPUT_AUTOFLUSH'
		exe "imenu ".s:Perl_Root.'Spec-&Var.&files.$FORMAT_LINES_LEFT<Tab>$-       $FORMAT_LINES_LEFT'
		exe "imenu ".s:Perl_Root.'Spec-&Var.&files.$FORMAT_LINES_PER_PAGE<Tab>$=   $FORMAT_LINES_PER_PAGE'
		exe "imenu ".s:Perl_Root.'Spec-&Var.&files.$FORMAT_NAME<Tab>$~             $FORMAT_NAME'
		exe "imenu ".s:Perl_Root.'Spec-&Var.&files.$FORMAT_PAGE_NUMBER<Tab>$%      $FORMAT_PAGE_NUMBER'
		exe "imenu ".s:Perl_Root.'Spec-&Var.&files.$FORMAT_TOP_NAME<Tab>$^         $FORMAT_TOP_NAME'

		"-------- submenu IDs -------------------------------------------------
		if s:Perl_MenuHeader == "yes"
			exe "amenu ".s:Perl_Root.'Spec-&Var.&IDs.Spec-Var-3<Tab>Perl    <Esc>'
			exe "amenu ".s:Perl_Root.'Spec-&Var.&IDs.-Sep0-                 :'
		endif
		exe " menu ".s:Perl_Root.'Spec-&Var.&IDs.$PID<Tab>$$                   <Esc>a$PID'
		exe " menu ".s:Perl_Root.'Spec-&Var.&IDs.$PROCESS_ID<Tab>$$            <Esc>a$PROCESS_ID'
		exe " menu ".s:Perl_Root.'Spec-&Var.&IDs.$GID<Tab>$(                   <Esc>a$GID'
		exe " menu ".s:Perl_Root.'Spec-&Var.&IDs.$REAL_GROUP_ID<Tab>$(         <Esc>a$REAL_GROUP_ID'
		exe " menu ".s:Perl_Root.'Spec-&Var.&IDs.$EGID<Tab>$)                  <Esc>a$EGID'
		exe " menu ".s:Perl_Root.'Spec-&Var.&IDs.$EFFECTIVE_GROUP_ID<Tab>$)    <Esc>a$EFFECTIVE_GROUP_ID'
		exe "imenu ".s:Perl_Root.'Spec-&Var.&IDs.$PID<Tab>$$                   $PID'
		exe "imenu ".s:Perl_Root.'Spec-&Var.&IDs.$PROCESS_ID<Tab>$$            $PROCESS_ID'
		exe "imenu ".s:Perl_Root.'Spec-&Var.&IDs.$GID<Tab>$(                   $GID'
		exe "imenu ".s:Perl_Root.'Spec-&Var.&IDs.$REAL_GROUP_ID<Tab>$(         $REAL_GROUP_ID'
		exe "imenu ".s:Perl_Root.'Spec-&Var.&IDs.$EGID<Tab>$)                  $EGID'
		exe "imenu ".s:Perl_Root.'Spec-&Var.&IDs.$EFFECTIVE_GROUP_ID<Tab>$)    $EFFECTIVE_GROUP_ID'

		"-------- submenu IO -------------------------------------------------
		if s:Perl_MenuHeader == "yes"
			exe "amenu ".s:Perl_Root.'Spec-&Var.I&O.Spec-Var-4<Tab>Perl       <Esc>'
			exe "amenu ".s:Perl_Root.'Spec-&Var.I&O.-Sep0-                    :'
		endif
		exe " menu ".s:Perl_Root.'Spec-&Var.I&O.$INPUT_LINE_NUMBER<Tab>$\.          <Esc>a$INPUT_LINE_NUMBER'
		exe " menu ".s:Perl_Root.'Spec-&Var.I&O.$NR<Tab>$\.                         <Esc>a$NR'
		exe "imenu ".s:Perl_Root.'Spec-&Var.I&O.$INPUT_LINE_NUMBER<Tab>$\.          $INPUT_LINE_NUMBER'
		exe "imenu ".s:Perl_Root.'Spec-&Var.I&O.$NR<Tab>$\.                         $NR'

		exe "imenu ".s:Perl_Root.'Spec-&Var.I&O.-SEP1-    					 		            :'
		exe " menu ".s:Perl_Root.'Spec-&Var.I&O.$INPUT_RECORD_SEPARATOR<Tab>$/     <Esc>a$INPUT_RECORD_SEPARATOR'
		exe " menu ".s:Perl_Root.'Spec-&Var.I&O.$RS<Tab>$/                         <Esc>a$RS'
		exe " menu ".s:Perl_Root.'Spec-&Var.I&O.$LIST_SEPARATOR<Tab>$"             <Esc>a$LIST_SEPARATOR'
		exe " menu ".s:Perl_Root.'Spec-&Var.I&O.$OUTPUT_FIELD_SEPARATOR<Tab>$,     <Esc>a$OUTPUT_FIELD_SEPARATOR'
		exe " menu ".s:Perl_Root.'Spec-&Var.I&O.$OFS<Tab>$,                        <Esc>a$OFS'
		exe " menu ".s:Perl_Root.'Spec-&Var.I&O.$OUTPUT_RECORD_SEPARATOR<Tab>$\\   <Esc>a$OUTPUT_RECORD_SEPARATOR'
		exe " menu ".s:Perl_Root.'Spec-&Var.I&O.$ORS<Tab>$\\                       <Esc>a$ORS'
		exe " menu ".s:Perl_Root.'Spec-&Var.I&O.$SUBSCRIPT_SEPARATOR<Tab>$;        <Esc>a$SUBSCRIPT_SEPARATOR'
		exe " menu ".s:Perl_Root.'Spec-&Var.I&O.$SUBSEP<Tab>$;                     <Esc>a$SUBSEP'

		exe "imenu ".s:Perl_Root.'Spec-&Var.I&O.$INPUT_RECORD_SEPARATOR<Tab>$/     $INPUT_RECORD_SEPARATOR'
		exe "imenu ".s:Perl_Root.'Spec-&Var.I&O.$RS<Tab>$/                         $RS'
		exe "imenu ".s:Perl_Root.'Spec-&Var.I&O.$LIST_SEPARATOR<Tab>$"             $LIST_SEPARATOR'
		exe "imenu ".s:Perl_Root.'Spec-&Var.I&O.$OUTPUT_FIELD_SEPARATOR<Tab>$,     $OUTPUT_FIELD_SEPARATOR'
		exe "imenu ".s:Perl_Root.'Spec-&Var.I&O.$OFS<Tab>$,                        $OFS'
		exe "imenu ".s:Perl_Root.'Spec-&Var.I&O.$OUTPUT_RECORD_SEPARATOR<Tab>$\\   $OUTPUT_RECORD_SEPARATOR'
		exe "imenu ".s:Perl_Root.'Spec-&Var.I&O.$ORS<Tab>$\\                       $ORS'
		exe "imenu ".s:Perl_Root.'Spec-&Var.I&O.$SUBSCRIPT_SEPARATOR<Tab>$;        $SUBSCRIPT_SEPARATOR'
		exe "imenu ".s:Perl_Root.'Spec-&Var.I&O.$SUBSEP<Tab>$;                     $SUBSEP'

		"-------- submenu regexp -------------------------------------------------
		if s:Perl_MenuHeader == "yes"
			exe "amenu ".s:Perl_Root.'Spec-&Var.&regexp.Spec-Var-5<Tab>Perl       <Esc>'
			exe "amenu ".s:Perl_Root.'Spec-&Var.&regexp.-Sep0-                    :'
		endif
		exe " menu ".s:Perl_Root.'Spec-&Var.&regexp.$digits                 				   <Esc>a$digits'
		exe " menu ".s:Perl_Root.'Spec-&Var.&regexp.@LAST_MATCH_END<Tab>@+             <Esc>a@LAST_MATCH_END'
		exe " menu ".s:Perl_Root.'Spec-&Var.&regexp.@LAST_MATCH_START<Tab>@-           <Esc>a@LAST_MATCH_START'
		exe " menu ".s:Perl_Root.'Spec-&Var.&regexp.$LAST_PAREN_MATCH<Tab>$+           <Esc>a$LAST_PAREN_MATCH'
		exe " menu ".s:Perl_Root.'Spec-&Var.&regexp.$LAST_REGEXP_CODE_RESULT<Tab>$^R   <Esc>a$LAST_REGEXP_CODE_RESULT'
		exe " menu ".s:Perl_Root.'Spec-&Var.&regexp.$MATCH<Tab>$&                      <Esc>a$MATCH'
		exe " menu ".s:Perl_Root."Spec-&Var.&regexp.$POSTMATCH<Tab>$'                  <Esc>a$POSTMATCH"
		exe " menu ".s:Perl_Root.'Spec-&Var.&regexp.$PREMATCH<Tab>$`                   <Esc>a$PREMATCH'
		exe "imenu ".s:Perl_Root.'Spec-&Var.&regexp.$digits            				         $digits'
		exe "imenu ".s:Perl_Root.'Spec-&Var.&regexp.@LAST_MATCH_END<Tab>$@+            @LAST_MATCH_END'
		exe "imenu ".s:Perl_Root.'Spec-&Var.&regexp.@LAST_MATCH_START<Tab>$@-          @LAST_MATCH_START'
		exe "imenu ".s:Perl_Root.'Spec-&Var.&regexp.$LAST_PAREN_MATCH<Tab>$+           $LAST_PAREN_MATCH'
		exe "imenu ".s:Perl_Root.'Spec-&Var.&regexp.$LAST_REGEXP_CODE_RESULT<Tab>$^R   $LAST_REGEXP_CODE_RESULT'
		exe "imenu ".s:Perl_Root.'Spec-&Var.&regexp.$MATCH<Tab>$&                      $MATCH'
		exe "imenu ".s:Perl_Root."Spec-&Var.&regexp.$POSTMATCH<Tab>$'                  $POSTMATCH"
		exe "imenu ".s:Perl_Root.'Spec-&Var.&regexp.$PREMATCH<Tab>$`                   $PREMATCH'

		exe " menu ".s:Perl_Root.'Spec-&Var.$BASETIME<Tab>$^T      		<Esc>a$BASETIME'
		exe " menu ".s:Perl_Root.'Spec-&Var.$PERL_VERSION<Tab>$^V  		<Esc>a$PERL_VERSION'
		exe " menu ".s:Perl_Root.'Spec-&Var.$PROGRAM_NAME<Tab>$0  		<Esc>a$PROGRAM_NAME'
		exe " menu ".s:Perl_Root.'Spec-&Var.$OSNAME<Tab>$^O       		<Esc>a$OSNAME'
		exe " menu ".s:Perl_Root.'Spec-&Var.$SYSTEM_FD_MAX<Tab>$^F 		<Esc>a$SYSTEM_FD_MAX'
		exe " menu ".s:Perl_Root.'Spec-&Var.$ENV{\ }			 				 		<Esc>a$ENV{}<ESC>i'
		exe " menu ".s:Perl_Root.'Spec-&Var.$INC{\ }			 				 		<Esc>a$INC{}<ESC>i'
		exe " menu ".s:Perl_Root.'Spec-&Var.$SIG{\ }			 				 		<Esc>a$SIG{}<ESC>i'
		exe "imenu ".s:Perl_Root.'Spec-&Var.$BASETIME<Tab>$^T      		$BASETIME'
		exe "imenu ".s:Perl_Root.'Spec-&Var.$PERL_VERSION<Tab>$^V  		$PERL_VERSION'
		exe "imenu ".s:Perl_Root.'Spec-&Var.$PROGRAM_NAME<Tab>$0  		$PROGRAM_NAME'
		exe "imenu ".s:Perl_Root.'Spec-&Var.$OSNAME<Tab>$^O       		$OSNAME'
		exe "imenu ".s:Perl_Root.'Spec-&Var.$SYSTEM_FD_MAX<Tab>$^F 		$SYSTEM_FD_MAX'
		exe "imenu ".s:Perl_Root.'Spec-&Var.$ENV{\ }				 			 		$ENV{}<ESC>i'
		exe "imenu ".s:Perl_Root.'Spec-&Var.$INC{\ }				 			 		$INC{}<ESC>i'
		exe "imenu ".s:Perl_Root.'Spec-&Var.$SIG{\ }				 			 		$SIG{}<ESC>i'
		"
		"---------- submenu : POSIX signals --------------------------------------
		"
		if s:Perl_MenuHeader == "yes"
			exe "amenu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.Spec-Var-6<Tab>Perl     <Esc>'
			exe "amenu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.-Sep0-        :'
		endif
		exe " menu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.HUP 		<Esc>aHUP'
		exe " menu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.INT 		<Esc>aINT'
		exe " menu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.QUIT		<Esc>aQUIT'
		exe " menu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.ILL 		<Esc>aILL'
		exe " menu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.ABRT		<Esc>aABRT'
		exe " menu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.FPE 		<Esc>aFPE'
		exe " menu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.KILL		<Esc>aKILL'
		exe " menu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.SEGV		<Esc>aSEGV'
		exe " menu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.PIPE		<Esc>aPIPE'
		exe " menu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.ALRM		<Esc>aALRM'
		exe " menu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.TERM		<Esc>aTERM'
		exe " menu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.USR1		<Esc>aUSR1'
		exe " menu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.USR2		<Esc>aUSR2'
		exe " menu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.CHLD		<Esc>aCHLD'
		exe " menu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.CONT		<Esc>aCONT'
		exe " menu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.STOP		<Esc>aSTOP'
		exe " menu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.TSTP		<Esc>aTSTP'
		exe " menu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.TTIN		<Esc>aTTIN'
		exe " menu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.TTOU		<Esc>aTTOU'
		"
		exe "imenu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.HUP 		HUP'
		exe "imenu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.INT 		INT'
		exe "imenu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.QUIT		QUIT'
		exe "imenu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.ILL 		ILL'
		exe "imenu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.ABRT		ABRT'
		exe "imenu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.FPE 		FPE'
		exe "imenu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.KILL		KILL'
		exe "imenu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.SEGV		SEGV'
		exe "imenu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.PIPE		PIPE'
		exe "imenu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.ALRM		ALRM'
		exe "imenu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.TERM		TERM'
		exe "imenu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.USR1		USR1'
		exe "imenu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.USR2		USR2'
		exe "imenu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.CHLD		CHLD'
		exe "imenu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.CONT		CONT'
		exe "imenu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.STOP		STOP'
		exe "imenu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.TSTP		TSTP'
		exe "imenu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.TTIN		TTIN'
		exe "imenu ".s:Perl_Root.'Spec-&Var.POSIX\ signals.TTOU		TTOU'
		"
		exe "imenu ".s:Perl_Root.'Spec-&Var.-SEP2-      		      :'
		exe " menu ".s:Perl_Root."Spec-&Var.\'IGNORE\' 						<Esc>a'IGNORE'"
		exe " menu ".s:Perl_Root."Spec-&Var.\'DEFAULT\' 					<Esc>a'DEFAULT'"
		exe "imenu ".s:Perl_Root."Spec-&Var.\'IGNORE\' 						'IGNORE'"
		exe "imenu ".s:Perl_Root."Spec-&Var.\'DEFAULT\' 					'DEFAULT'"
		exe "imenu ".s:Perl_Root.'Spec-&Var.-SEP3-      		      :'
		exe "amenu ".s:Perl_Root.'Spec-&Var.use\ English; 				<ESC><ESC>ouse English qw( -no_match_vars );'
		"
		"---------- POD-Menu ----------------------------------------------------------------------
		"
		if s:Perl_MenuHeader == "yes"
			exe "amenu ".s:Perl_Root.'&POD.POD<Tab>Perl           <Esc>'
			exe "amenu ".s:Perl_Root.'&POD.-Sep0-                 :'
		endif
		"
		exe "amenu ".s:Perl_Root.'&POD.=&pod\ /\ =cut            <Esc><Esc>o'.s:Perl_POD_cut.'<Esc>3kA'
		exe "amenu ".s:Perl_Root.'&POD.=c&ut                     <Esc><Esc>o<CR>=cut<CR><CR><Esc>A'
		exe "amenu ".s:Perl_Root.'&POD.=fo&r\ /\ =cut            <Esc><Esc>o'.s:Perl_POD_for.'<Esc>3kA'
		exe "amenu ".s:Perl_Root.'&POD.=begin\ &html\ /\ =end    <Esc><Esc>o'.s:Perl_POD_html.'<Esc>3kA'
		exe "amenu ".s:Perl_Root.'&POD.=begin\ &man\ /\ =end     <Esc><Esc>o'.s:Perl_POD_man.'<Esc>3kA'
		exe "amenu ".s:Perl_Root.'&POD.=begin\ &text\ /\ =end    <Esc><Esc>o'.s:Perl_POD_text.'<Esc>3kA'
		exe "amenu ".s:Perl_Root.'&POD.=head&1                   <Esc><Esc>o<CR>=head1 <CR><Esc>kA'
		exe "amenu ".s:Perl_Root.'&POD.=head&2                   <Esc><Esc>o<CR>=head2 <CR><Esc>kA'
		exe "amenu ".s:Perl_Root.'&POD.=head&3                   <Esc><Esc>o<CR>=head3 <CR><Esc>kA'
		exe "amenu ".s:Perl_Root.'&POD.-Sep1-                    :'
		exe "amenu ".s:Perl_Root.'&POD.=&over\ \.\.\ =back       <Esc><Esc>o'.s:Perl_POD_List.'<Esc>8kA'
		exe "amenu ".s:Perl_Root.'&POD.=item\ &*                 <Esc><Esc>o<CR>=item *<CR><CR><CR><Esc>kA'
		exe "amenu ".s:Perl_Root.'&POD.-Sep2-                    :'
		"
		if s:Perl_MenuHeader == "yes"
			exe "amenu ".s:Perl_Root.'&POD.in&visible\ POD.invisible\ POD<Tab>Perl     <Esc>'
			exe "amenu ".s:Perl_Root.'&POD.in&visible\ POD.-Sep0-        :'
		endif
		exe "amenu <silent> ".s:Perl_Root.'&POD.in&visible\ POD.&Improvement   <Esc><C-C>:call Perl_InvisiblePOD("Improvement")<CR>'
		exe "amenu <silent> ".s:Perl_Root.'&POD.in&visible\ POD.&Optimization  <Esc><C-C>:call Perl_InvisiblePOD("Optimization")<CR>'
		exe "amenu <silent> ".s:Perl_Root.'&POD.in&visible\ POD.&Rationale     <Esc><C-C>:call Perl_InvisiblePOD("Rationale")<CR>'
		exe "amenu <silent> ".s:Perl_Root.'&POD.in&visible\ POD.&Workaround    <Esc><C-C>:call Perl_InvisiblePOD("Workaround")<CR>'
		exe "amenu ".s:Perl_Root.'&POD.-Sep3-                    :'
		"
		"---------- submenu : Sequences --------------------------------------
		"
		exe "amenu ".s:Perl_Root.'&POD.&B<><Tab>bold             <Esc><Esc>aB<><Esc>i'
		exe "amenu ".s:Perl_Root.'&POD.&C<><Tab>literal          <Esc><Esc>aC<><Esc>i'
		exe "amenu ".s:Perl_Root.'&POD.&E<><Tab>escape           <Esc><Esc>aE<><Esc>i'
		exe "amenu ".s:Perl_Root.'&POD.&F<><Tab>filename         <Esc><Esc>aF<><Esc>i'
		exe "amenu ".s:Perl_Root.'&POD.&I<><Tab>italic           <Esc><Esc>aI<><Esc>i'
		exe "amenu ".s:Perl_Root.'&POD.&L<><Tab>link             <Esc><Esc>aL<\|><Esc>hi'
		exe "amenu ".s:Perl_Root.'&POD.&S<>\ \ nonbr\.\ spaces   <Esc><Esc>aS<><Esc>i'
		exe "amenu ".s:Perl_Root.'&POD.&X<><Tab>index            <Esc><Esc>aX<><Esc>i'
		exe "amenu ".s:Perl_Root.'&POD.&Z<><Tab>zero-width       <Esc>aZ<><Esc>a'
		"
		exe "vmenu ".s:Perl_Root.'&POD.&B<><Tab>bold                    sB<><Esc>P2l'
		exe "vmenu ".s:Perl_Root.'&POD.&C<><Tab>literal                 sC<><Esc>P2l'
		exe "vmenu ".s:Perl_Root.'&POD.&E<><Tab>escape                  sE<><Esc>P2l'
		exe "vmenu ".s:Perl_Root.'&POD.&F<><Tab>filename                sF<><Esc>P2l'
		exe "vmenu ".s:Perl_Root.'&POD.&I<><Tab>italic                  sI<><Esc>P2l'
		exe "vmenu ".s:Perl_Root.'&POD.&L<><Tab>link                    sL<\|><Esc>hPl'
		exe "vmenu ".s:Perl_Root.'&POD.&S<>\ \ nonbr\.\ spaces          sS<><Esc>P2l'
		exe "vmenu ".s:Perl_Root.'&POD.&X<><Tab>index                   sX<><Esc>P2l'

		exe "amenu          ".s:Perl_Root.'&POD.-SEP4-      		        :'
		exe "amenu <silent> ".s:Perl_Root.'&POD.POD\ ->\ html\ \ (&4)   <Esc><C-C>:call Perl_POD("html")<CR>'
		exe "amenu <silent> ".s:Perl_Root.'&POD.POD\ ->\ man\ \ (&5)    <Esc><C-C>:call Perl_POD("man")<CR>'
		exe "amenu <silent> ".s:Perl_Root.'&POD.POD\ ->\ text\ \ (&6)   <Esc><C-C>:call Perl_POD("text")<CR>'
		"
		"---------- Run-Menu ----------------------------------------------------------------------
		"
		if s:Perl_MenuHeader == "yes"
			exe "amenu ".s:Perl_Root.'&Run.Run<Tab>Perl                   <Esc>'
			exe "amenu ".s:Perl_Root.'&Run.-Sep0-                         :'
		endif
		"
		"   run the script from the local directory 
		"   ( the one which is being edited; other versions may exist elsewhere ! )
		" 
		exe "amenu <silent> ".s:Perl_Root.'&Run.update,\ &run\ script<Tab><C-F9>   			         <C-C>:call Perl_Run()<CR>'
		"
		exe "amenu ".s:Perl_Root.'&Run.update,\ check\ &syntax<Tab><A-F9>       			   <C-C>:call Perl_SyntaxCheck()<CR>:redraw<CR>:call Perl_SyntaxCheckMsg()<CR>'
		exe "amenu <silent> ".s:Perl_Root.'&Run.cmd\.\ line\ &arg\.<Tab><S-F9>           <C-C>:call Perl_Arguments()<CR>'
		exe "amenu <silent> ".s:Perl_Root.'&Run.start\ &debugger<Tab><F9>                <C-C>:call Perl_Debugger()<CR>'
		"
		"   set execution rights for user only ( user may be root ! )
		"
		if !s:MSWIN
			exe "amenu <silent> ".s:Perl_Root.'&Run.make\ script\ &executable              <C-C>:call Perl_MakeScriptExecutable()<CR>'
		endif
		exe "amenu          ".s:Perl_Root.'&Run.-SEP2-                           :'

		exe "amenu <silent> ".s:Perl_Root.'&Run.read\ &perldoc<Tab><S-F1>        <C-C>:call Perl_perldoc()<CR><CR>'
		exe "amenu <silent> ".s:Perl_Root.'&Run.show\ &installed\ Perl\ modules  <Esc><Esc>:call Perl_perldoc_show_module_list()<CR>'
		exe "amenu <silent> ".s:Perl_Root.'&Run.&generate\ Perl\ module\ list    <C-C>:call Perl_perldoc_generate_module_list()<CR><CR>'
		"
		exe "amenu          ".s:Perl_Root.'&Run.-SEP4-                           :'
		exe "amenu <silent> ".s:Perl_Root.'&Run.run\ perltid&y                   <C-C>:call Perl_Perltidy("n")<CR>'
		exe "vmenu <silent> ".s:Perl_Root.'&Run.run\ perltid&y                   <C-C>:call Perl_Perltidy("v")<CR>'
		exe "amenu <silent> ".s:Perl_Root.'&Run.run\ S&mallProf                  <C-C>:call Perl_Smallprof()<CR><CR>'
		exe "amenu <silent> ".s:Perl_Root.'&Run.save\ buffer\ with\ &timestamp   <C-C>:call Perl_SaveWithTimestamp()<CR>'

		exe "amenu          ".s:Perl_Root.'&Run.-SEP5-                           :'
		exe "amenu <silent> ".s:Perl_Root.'&Run.&hardcopy\ to\ FILENAME\.ps      <C-C>:call Perl_Hardcopy("n")<CR>'
		exe "vmenu <silent> ".s:Perl_Root.'&Run.&hardcopy\ to\ FILENAME\.ps      <C-C>:call Perl_Hardcopy("v")<CR>'
		exe "amenu          ".s:Perl_Root.'&Run.-SEP6-                           :'
		exe "amenu <silent> ".s:Perl_Root.'&Run.settings\ and\ hot\ &keys        <C-C>:call Perl_Settings()<CR>'
		"
		if	!s:MSWIN
			exe "amenu  <silent>  ".s:Perl_Root.'&Run.&xterm\ size                             <C-C>:call Perl_XtermSize()<CR>'
		endif
		if s:Perl_OutputGvim == "vim" 
			exe "amenu  <silent>  ".s:Perl_Root.'&Run.&output:\ VIM->buffer->xterm            <C-C>:call Perl_Toggle_Gvim_Xterm()<CR><CR>'
		else
			if s:Perl_OutputGvim == "buffer" 
				exe "amenu  <silent>  ".s:Perl_Root.'&Run.&output:\ BUFFER->xterm->vim        <C-C>:call Perl_Toggle_Gvim_Xterm()<CR><CR>'
			else
				exe "amenu  <silent>  ".s:Perl_Root.'&Run.&output:\ XTERM->vim->buffer          <C-C>:call Perl_Toggle_Gvim_Xterm()<CR><CR>'
			endif
		endif
		"
	endif
	"
	"--------------------------------------------------------------------------------------------
	"
endfunction		" ---------- end of function  Perl_InitMenu  ----------
"
"
"------------------------------------------------------------------------------
"-----   variables for internal use   -----------------------------------------
"------------------------------------------------------------------------------
"
let s:Perl_Active       = -1				" state variable controlling the Perl-menus
"
"
"------------------------------------------------------------------------------
"  Input after a highlighted prompt
"------------------------------------------------------------------------------
function! Perl_Input ( promp, text )
  echohl Search                       " highlight prompt
  call inputsave()                    " preserve typeahead
  let retval=input( a:promp, a:text ) " read input
  call inputrestore()                 " restore typeahead
  echohl None                         " reset highlighting
  return retval
endfunction		" ---------- end of function  Perl_Input  ----------
"
"------------------------------------------------------------------------------
"  Comments : get line-end comment position
"------------------------------------------------------------------------------
function! Perl_GetLineEndCommCol ()
  let	b:Perl_LineEndCommentColumn	= virtcol(".") 
  echomsg "line end comments will start at column  ".b:Perl_LineEndCommentColumn
endfunction		" ---------- end of function  Perl_GetLineEndCommCol  ----------
"
"------------------------------------------------------------------------------
"  Comments : single line-end comment
"------------------------------------------------------------------------------
function! Perl_LineEndComment ()
	if !exists("b:Perl_LineEndCommentColumn")
		let	b:Perl_LineEndCommentColumn	= s:Perl_LineEndCommColDefault
	endif
	" ----- trim whitespaces -----
	exe "s/\s\*$//"
	let linelength= virtcol("$") - 1
	if linelength < b:Perl_LineEndCommentColumn
		let diff	= b:Perl_LineEndCommentColumn -1 -linelength
		exe "normal	".diff."A "
	endif
	" append at least one blank
	if linelength >= b:Perl_LineEndCommentColumn
		exe "normal A "
	endif
	exe "normal A# "
endfunction		" ---------- end of function  Perl_LineEndComment  ----------
"
"------------------------------------------------------------------------------
"  Comments : multi line-end comments
"------------------------------------------------------------------------------
function! Perl_MultiLineEndComments ()
  if !exists("b:Perl_LineEndCommentColumn")
		let	b:Perl_LineEndCommentColumn	= s:Perl_LineEndCommColDefault
  endif
	"
	let pos0	= line("'<")
	let pos1	= line("'>")
	" ----- trim whitespaces -----
	exe "'<,'>s/\s\*$//"
	" ----- find the longest line -----
	let	maxlength		= 0
	let	linenumber	= pos0
	normal '<
	while linenumber <= pos1
		if  getline(".") !~ "^\\s*$"  && maxlength<virtcol("$")
			let maxlength= virtcol("$")
		endif
		let linenumber=linenumber+1
		normal j
	endwhile
	"
	if maxlength < b:Perl_LineEndCommentColumn
	  let maxlength = b:Perl_LineEndCommentColumn
	else
	  let maxlength = maxlength+1		" at least 1 blank
	endif
	"
	" ----- fill lines with blanks -----
	let	linenumber	= pos0
	normal '<
	while linenumber <= pos1
		if getline(".") !~ "^\\s*$"
			let diff	= maxlength - virtcol("$")
			exe "normal	".diff."A "
			exe "normal	$A# "
		endif
		let linenumber=linenumber+1
		normal j
	endwhile
	" ----- back to the begin of the marked block -----
	normal '<
endfunction		" ---------- end of function  Perl_MultiLineEndComments  ----------
"
"------------------------------------------------------------------------------
"  Comments : classified comments
"------------------------------------------------------------------------------
function! Perl_CommentClassified (class)
  	put = '# :'.a:class.':'.strftime(\"%x\").':'.s:Perl_AuthorRef.': '
endfunction		" ---------- end of function  Perl_CommentClassified  ----------
"
"------------------------------------------------------------------------------
"  Substitute tags
"------------------------------------------------------------------------------
function! Perl_SubstituteTag( pos1, pos2, tag, replacement )
	" 
	" loop over marked block
	" 
	let	linenumber=a:pos1
	while linenumber <= a:pos2
		let line=getline(linenumber)
		" 
		" loop for multiple tags in one line
		" 
		let	start=0
		while match(line,a:tag,start)>=0				" do we have a tag ?
			let frst=match(line,a:tag,start)
			let last=matchend(line,a:tag,start)
			if frst!=-1
				let part1=strpart(line,0,frst)
				let part2=strpart(line,last)
				let line=part1.a:replacement.part2
				"
				" next search starts after the replacement to suppress recursion
				" 
				let start=strlen(part1)+strlen(a:replacement)
			endif
		endwhile
		call setline( linenumber, line )
		let	linenumber=linenumber+1
	endwhile

endfunction    " ----------  end of function  Perl_SubstituteTag  ----------
"
"------------------------------------------------------------------------------
"  Comments : Insert Template Files
"------------------------------------------------------------------------------
function! Perl_CommentTemplates (arg)

	"----------------------------------------------------------------------
	"  Perl templates
	"----------------------------------------------------------------------
	if a:arg=='frame'
		let templatefile=s:Perl_Template_Directory.s:Perl_Template_Frame
	endif

	if a:arg=='function'
		let templatefile=s:Perl_Template_Directory.s:Perl_Template_Function
	endif

	if a:arg=='header'
		let templatefile=s:Perl_Template_Directory.s:Perl_Template_File
	endif

	if a:arg=='module'
		let templatefile=s:Perl_Template_Directory.s:Perl_Template_Module
	endif


	if filereadable(templatefile)
		let	length= line("$")
		let	pos1  = line(".")+1
		let l:old_cpoptions	= &cpoptions " Prevent the alternate buffer from being set to this files
		setlocal cpoptions-=a
		if  a:arg=='header'|| a:arg=='module' 
			:goto 1
			let	pos1  = 1
			exe '0read '.templatefile
		else
			exe 'read '.templatefile
		endif
		let &cpoptions	= l:old_cpoptions		" restore previous options
		"
		let	length= line("$")-length
		let	pos2  = pos1+length-1
		"----------------------------------------------------------------------
		"  frame blocks will be indented
		"----------------------------------------------------------------------
		if a:arg=='frame'
			let	length	= length-1
			silent exe "normal =".length."+"
			let	length	= length+1
		endif
		"----------------------------------------------------------------------
		"  substitute keywords
		"----------------------------------------------------------------------
		" 
		call Perl_SubstituteTag( pos1, pos2, '|FILENAME|',        expand("%:t")          )
		call Perl_SubstituteTag( pos1, pos2, '|DATE|',            strftime("%x %X %Z")   )
		call Perl_SubstituteTag( pos1, pos2, '|TIME|',            strftime("%X")         )
		call Perl_SubstituteTag( pos1, pos2, '|YEAR|',            strftime("%Y")         )
		call Perl_SubstituteTag( pos1, pos2, '|AUTHOR|',          s:Perl_AuthorName      )
		call Perl_SubstituteTag( pos1, pos2, '|EMAIL|',           s:Perl_Email           )
		call Perl_SubstituteTag( pos1, pos2, '|AUTHORREF|',       s:Perl_AuthorRef       )
		call Perl_SubstituteTag( pos1, pos2, '|PROJECT|',         s:Perl_Project         )
		call Perl_SubstituteTag( pos1, pos2, '|COMPANY|',         s:Perl_Company         )
		call Perl_SubstituteTag( pos1, pos2, '|COPYRIGHTHOLDER|', s:Perl_CopyrightHolder )
		"
		"----------------------------------------------------------------------
		"  Position the cursor
		"----------------------------------------------------------------------
		exe ':'.pos1
		normal 0
		let linenumber=search('|CURSOR|')
		if linenumber >=pos1 && linenumber<=pos2
			let pos1=match( getline(linenumber) ,"|CURSOR|")
			if  matchend( getline(linenumber) ,"|CURSOR|") == match( getline(linenumber) ,"$" )
				silent! s/|CURSOR|//
				" this is an append like A
				:startinsert!
			else
				silent  s/|CURSOR|//
				call cursor(linenumber,pos1+1)
				" this is an insert like i
				:startinsert
			endif
		endif

	else
		echohl WarningMsg | echo 'template file '.templatefile.' does not exist or is not readable'| echohl None
	endif
	return
endfunction    " ----------  end of function  Perl_CommentTemplates  ----------
"
"------------------------------------------------------------------------------
"  Comments : vim modeline
"------------------------------------------------------------------------------
function! Perl_CommentVimModeline ()
	put = '# vim: set tabstop='.&tabstop.' shiftwidth='.&shiftwidth.': '
endfunction    " ----------  end of function Perl_CommentVimModeline  ----------
"
"------------------------------------------------------------------------------
"  Statements : subroutine
"------------------------------------------------------------------------------
function! Perl_Subroutine (arg1)
	let	identifier=Perl_Input("subroutine name : ", "" )
	"
	" ----- normal mode ----------------
	if a:arg1=="a" 
		if s:Perl_BraceOnNewLine == "no"
			let zz=    "sub ".identifier." {\n\tmy\t($par1)\t= @_;\n\t\n\treturn ;\n}"
			let zz= zz."\t# ----------  end of subroutine ".identifier."  ----------" 
			put =zz
			normal 2j
		else
			let zz=    "sub ".identifier."\n{\n\tmy\t($par1)\t= @_;\n\t\n\treturn ;\n}"
			let zz= zz."\t# ----------  end of subroutine ".identifier."  ----------" 
			put =zz
			normal 3j
		endif
	endif
	"
	" ----- visual mode ----------------
	if a:arg1=="v" 
		if s:Perl_BraceOnNewLine == "no"
			let zz=    "sub ".identifier." {\n\tmy\t($par1)\t= @_;"
			:'<put! =zz
			let zz=    "\treturn ;\n}"
			let zz= zz."\t# ----------  end of subroutine ".identifier."  ----------" 
			:'>put =zz
			:'<-3
			let zz=    identifier."();\n\n"
			:put =zz
			:exe "normal =".(line("'>")-line(".")+2)."+"
		else
			let zz=    "sub ".identifier."\n{\n\tmy\t($par1)\t= @_;"
			:'<put! =zz
			let zz=    "\treturn ;\n}"
			let zz= zz."\t# ----------  end of subroutine ".identifier."  ----------" 
			:'>put =zz
			:'<-4
			let zz=    identifier."();\n\n"
			:put =zz
			:exe "normal =".(line("'>")-line(".")+2)."+"
		endif
	endif
endfunction		" ---------- end of function  Perl_Subroutine  ----------
"
"------------------------------------------------------------------------------
"  Statements : do-while
"------------------------------------------------------------------------------
"
function! Perl_DoWhile (arg)

	if a:arg=='a'
		if s:Perl_BraceOnNewLine == "no"
			let zz=    "do {\n\t\n}\nwhile (  );"
			let zz= zz."\t\t\t\t# -----  end do-while  -----\n"
			put =zz
			normal	=3+
		else
			let zz=    "do\n{\n\t\n}\nwhile (  );"
			let zz= zz."\t\t\t\t# -----  end do-while  -----\n"
			put =zz
			normal	=4+
		endif
	endif

	if a:arg=='v'
		if s:Perl_BraceOnNewLine == "no"
			let zz=    "do {"
		else
			let zz=    "do\n{"
		endif
		:'<put! =zz
		let zz=    "}\nwhile (  );\t\t\t\t# -----  end do-while  -----\n"
		:'>put =zz
		:'<-2
		:exe "normal =".(line("'>")-line(".")+3)."+"
		:'>+2
	endif

endfunction		" ---------- end of function  Perl_DoWhile  ----------
"
"------------------------------------------------------------------------------
"  Perl-Idioms : CodeOpenRead
"------------------------------------------------------------------------------
function! Perl_OpenInputFile ()

	let	filehandle=Perl_Input("input file handle : ", "INFILE")
	
	if filehandle==""
		let	filehandle	= "INFILE"
	endif
	
	let filename=filehandle."_file_name"

	let zz=    "my\t$".filename." = \'\';\t\t# input file name\n\n"
	let zz= zz."open ( ".filehandle.", \'<\', $".filename." )\n"
	let zz= zz."\tor die  \"$0 : failed to open  input file $".filename." : $!\\n\";\n\n\n"
	let zz= zz."close ( ".filehandle." )\n"
	let zz= zz."\tor warn \"$0 : failed to close input file $".filename." : $!\\n\";\n\n\n"
	exe " menu ".s:Perl_Root.'I&dioms.<'.filehandle.'>     i<'.filehandle.'><ESC>'
	exe "vmenu ".s:Perl_Root.'I&dioms.<'.filehandle.'>     s<'.filehandle.'><ESC>'
	exe "imenu ".s:Perl_Root.'I&dioms.<'.filehandle.'>      <'.filehandle.'><ESC>a'
	put =zz
	normal =6+
	normal f'
endfunction		" ---------- end of function  Perl_OpenInputFile  ----------
"
"------------------------------------------------------------------------------
"  Perl-Idioms : CodeOpenWrite
"------------------------------------------------------------------------------
function! Perl_OpenOutputFile ()

	let	filehandle=Perl_Input("output file handle : ", "OUTFILE")
	
	if filehandle==""
		let	filehandle	= "OUTFILE"
	endif
	
	let filename=filehandle."_file_name"

	let zz=    "my\t$".filename." = \'\';\t\t# output file name\n\n"
	let zz= zz."open ( ".filehandle.", \'>\', $".filename." )\n"
	let zz= zz."\tor die  \"$0 : failed to open  output file $".filename." : $!\\n\";\n\n\n"
	let zz= zz."close ( ".filehandle." )\n"
	let zz= zz."\tor warn \"$0 : failed to close output file $".filename." : $!\\n\";\n\n\n"
	put =zz
	normal =6+
	exe " menu ".s:Perl_Root.'I&dioms.print\ '.filehandle.'\ "\\n";   iprint '.filehandle.' "\n";<ESC>3hi'
	exe "imenu ".s:Perl_Root.'I&dioms.print\ '.filehandle.'\ "\\n";    print '.filehandle.' "\n";<ESC>3hi'
	normal f'
endfunction		" ---------- end of function  Perl_OpenOutputFile  ----------
"
"------------------------------------------------------------------------------
"  Perl-Idioms : CodeOpenPipe
"------------------------------------------------------------------------------
function! Perl_OpenPipe ()

	let	filehandle=Perl_Input("pipe handle : ", "PIPE")

	if filehandle==""
		let	filehandle	= "PIPE"
	endif
	
	let pipecommand=filehandle."_command"

	let zz=    "my\t$".pipecommand." = \'\';\t\t# pipe command\n\n"
	let zz= zz."open ( ".filehandle.", $".pipecommand." )\n"
	let zz= zz."\tor die  \"$0 : failed to open  pipe > $".pipecommand." < : $!\\n\";\n\n\n"
	let zz= zz."close ( ".filehandle." )\n"
	let zz= zz."\tor warn \"$0 : failed to close pipe > $".pipecommand." < : $!\\n\";\n\n\n"
	put =zz
	normal =6+
	normal f'
endfunction		" ---------- end of function  Perl_OpenPipe  ----------
"
"------------------------------------------------------------------------------
"  Perl-Idioms : read / edit code snippet
"------------------------------------------------------------------------------
function! Perl_CodeSnippet(arg1)
	if isdirectory(s:Perl_CodeSnippets)
		"
		" read snippet file, put content below current line
		" 
		if a:arg1 == "r"
			let	l:snippetfile=browse(0,"read a code snippet",s:Perl_CodeSnippets,"")
			if filereadable(l:snippetfile)
				let	linesread= line("$")
				let l:old_cpoptions	= &cpoptions " Prevent the alternate buffer from being set to this files
				setlocal cpoptions-=a
				:execute "read ".l:snippetfile
				let &cpoptions	= l:old_cpoptions		" restore previous options
				"
				let	linesread= line("$")-linesread-1
				if linesread>=0 && match( l:snippetfile, '\.\(ni\|noindent\)$' ) < 0 
					silent exe "normal =".linesread."+"
				endif
			endif
		endif
		"
		" update current buffer / split window / edit snippet file
		" 
		if a:arg1 == "e"
			let	l:snippetfile=browse(0,"edit a code snippet",s:Perl_CodeSnippets,"")
			if l:snippetfile != ""
				:execute "update! | split | edit ".l:snippetfile
			endif
		endif
		"
		" write whole buffer into snippet file 
		" 
		if a:arg1 == "w"
			let	l:snippetfile=browse(0,"write a code snippet",s:Perl_CodeSnippets,"")
			if l:snippetfile != ""
				if filereadable(l:snippetfile)
					if confirm("File ".l:snippetfile." exists ! Overwrite ? ", "&Cancel\n&No\n&Yes") != 3
						return
					endif
				endif
				:execute ":write! ".l:snippetfile
			endif
		endif
		"
		" write marked area into snippet file 
		" 
		if a:arg1 == "wv"
			let	l:snippetfile=browse(0,"write a code snippet",s:Perl_CodeSnippets,"")
			if l:snippetfile != ""
				if filereadable(l:snippetfile)
					if confirm("File ".l:snippetfile." exists ! Overwrite ? ", "&Cancel\n&No\n&Yes") != 3
						return
					endif
				endif
				:execute ":*write! ".l:snippetfile
			endif
		endif

	else
		redraw
		echohl ErrorMsg
		echo "code snippet directory ".s:Perl_CodeSnippets." does not exist"
		echohl None
	endif
endfunction		" ---------- end of function  Perl_CodeSnippet  ----------
"
"------------------------------------------------------------------------------
"  Perl-Run : Perl_perldoc - lookup word under the cursor or ask
"------------------------------------------------------------------------------
"
let s:Perl_PerldocBufferName       = "PERLDOC"
let s:Perl_PerldocHelpBufferNumber = -1
let s:Perl_PerldocModulelistBuffer = -1
let s:Perl_PerldocSearchWord       = ""
let s:Perl_PerldocTry              = "module"
"
function! Perl_perldoc()

	let	buffername	= getcwd()."/".bufname("%")
	if( buffername == s:Perl_PerlModuleList )
		normal 0
		let	item=expand("<cWORD>")				" WORD under the cursor 
	else
		let	item=expand("<cword>")				" word under the cursor 
	endif
	if  item == ""
		let	item=Perl_Input("perldoc - module, function or FAQ keyword : ", "")
	endif

	"------------------------------------------------------------------------------
	"  replace buffer content with Perl documentation
	"------------------------------------------------------------------------------
	if item != ""
		"
		" jump to an already open PERLDOC window or create one
		" 
		if bufloaded(s:Perl_PerldocBufferName) != 0 && bufwinnr(s:Perl_PerldocHelpBufferNumber) != -1
			exe bufwinnr(s:Perl_PerldocHelpBufferNumber) . "wincmd w"
			" buffer number may have changed, e.g. after a 'save as' 
			if bufnr("%") != s:Perl_PerldocHelpBufferNumber
				let s:Perl_PerldocHelpBufferNumber=bufnr(s:Perl_OutputBufferName)
				exe ":bn ".s:Perl_PerldocHelpBufferNumber
			endif
		else
			exe ":new ".s:Perl_PerldocBufferName
			let s:Perl_PerldocHelpBufferNumber=bufnr("%")
			setlocal buftype=nofile
			setlocal noswapfile
			setlocal bufhidden=delete
			setlocal filetype=perl		" allows repeated use of <S-F1>
			setlocal syntax=OFF
		endif
		"
		" search order:  library module --> builtin function --> FAQ keyword
		" 
		let delete_perldoc_errors	= ""
		if has("unix")
			let delete_perldoc_errors	= " 2>/dev/null"
		endif
		setlocal	modifiable
		"
		" controll repeated search
		"
		if item == s:Perl_PerldocSearchWord
			" last item : search ring :
			if s:Perl_PerldocTry == 'module'
				let next  = 'function'
			endif
			if s:Perl_PerldocTry == 'function'
				let next  = 'faq'
			endif
			if s:Perl_PerldocTry == 'faq'
				let next  = 'module'
			endif
			let s:Perl_PerldocTry = next
		else
			" new item :
			let s:Perl_PerldocSearchWord	= item
			let s:Perl_PerldocTry         = 'module'
		endif
		"
		" module documentation
		if s:Perl_PerldocTry == 'module'
			let command=":%!perldoc  ".s:Perl_perldoc_flags." ".item.delete_perldoc_errors
			silent exe command
			if v:shell_error != 0
				redraw!
				let s:Perl_PerldocTry         = 'function'
			endif
		endif
		"
		" function documentation
		if s:Perl_PerldocTry == 'function'
			" -otext has to be ahead of -f and -q
			silent exe ":%!perldoc ".s:Perl_perldoc_flags." -f ".item.delete_perldoc_errors
			if v:shell_error != 0
				redraw!
				let s:Perl_PerldocTry         = 'faq'
			endif
		endif
		"
		" FAQ documentation
		if s:Perl_PerldocTry == 'faq'
			silent exe ":%!perldoc ".s:Perl_perldoc_flags." -q ".item.delete_perldoc_errors
			if v:shell_error != 0
				redraw!
				let s:Perl_PerldocTry         = 'error'
			endif
		endif
		"
		" no documentation found
		if s:Perl_PerldocTry == 'error'
			redraw!
			let zz=   "No documentation found for perl module, perl function or perl FAQ keyword\n"
			let zz=zz."  '".item."'  "
			silent put!	=zz
			normal	2jdd$
			let s:Perl_PerldocTry         = 'module'
			let s:Perl_PerldocSearchWord	= ""
		endif
		if has("unix")
			" remove windows line ends
			silent! exe ":%s/\r$// | normal gg"
		endif
		setlocal nomodifiable
		redraw!
	endif
endfunction		" ---------- end of function  Perl_perldoc  ----------
"
"------------------------------------------------------------------------------
"  Perl-Run : Perl_perldoc - show module list
"------------------------------------------------------------------------------
function! Perl_perldoc_show_module_list()
	if !filereadable(s:Perl_PerlModuleList)
		redraw
		echohl WarningMsg | echo 'Have to create '.s:Perl_PerlModuleList.' for the first time:'| echohl None
		call Perl_perldoc_generate_module_list()
	endif
	"
	" jump to the already open buffer or create one
	" 
	if bufexists(s:Perl_PerldocModulelistBuffer) && bufwinnr(s:Perl_PerldocModulelistBuffer)!=-1
		silent exe bufwinnr(s:Perl_PerldocModulelistBuffer) . "wincmd w"
	else
		silent exe "view ".s:Perl_PerlModuleList
		let s:Perl_PerldocModulelistBuffer=bufnr("%")
		setlocal nomodifiable
		setlocal filetype=perl
		setlocal syntax=none
	endif
	normal gg
	redraw
	if has("gui_running")
		echohl Search | echomsg 'use S-F1 to show a manual' | echohl None
	else
		echohl Search | echomsg 'use \hh in normal mode to show a manual' | echohl None
	endif
endfunction		" ---------- end of function  Perl_perldoc_show_module_list  ----------
"
"------------------------------------------------------------------------------
"  Perl-Run : Perl_perldoc - generate module list
"------------------------------------------------------------------------------
function! Perl_perldoc_generate_module_list()
	echohl Search
	echo " ... generating Perl module list ... " 
	setlocal modifiable
	if	s:MSWIN
		silent exe ":!".s:Perl_PerlModuleListGenerator." > ".s:Perl_PerlModuleList
		silent exe ":!sort ".s:Perl_PerlModuleList." /O ".s:Perl_PerlModuleList
	else
		silent exe ":!".s:Perl_PerlModuleListGenerator." -s > ".s:Perl_PerlModuleList
	endif
	setlocal nomodifiable
	echo " DONE " 
	echohl None
endfunction		" ---------- end of tion  Perl_perldoc_generate_module_list  ----------
"
"------------------------------------------------------------------------------
"  Run : settings
"------------------------------------------------------------------------------
function! Perl_Settings ()
	let	txt =     "  Perl-Support settings\n\n"
	let txt = txt.'            author name  :  "'.s:Perl_AuthorName."\"\n"
	let txt = txt.'               initials  :  "'.s:Perl_AuthorRef."\"\n"
	let txt = txt.'                  email  :  "'.s:Perl_Email."\"\n"
	let txt = txt.'                company  :  "'.s:Perl_Company."\"\n"
	let txt = txt.'                project  :  "'.s:Perl_Project."\"\n"
	let txt = txt.'       copyright holder  :  "'.s:Perl_CopyrightHolder."\"\n"
	let txt = txt." code snippet directory  :  ".s:Perl_CodeSnippets."\n"
	let txt = txt."     template directory  :  ".s:Perl_Template_Directory."\n"
	if g:Perl_Dictionary_File != ""
		let ausgabe = substitute( g:Perl_Dictionary_File, ",", ",\n                          + ", "g" )
		let txt     = txt."      dictionary file(s) :  ".ausgabe."\n"
	endif
	let txt = txt."   current output dest.  :  ".s:Perl_OutputGvim."\n"
	let txt = txt."\n"
	let txt = txt."    Additional hot keys\n\n"
	let txt = txt."               Shift-F1  :  read perldoc (for word under cursor)\n"
  let txt = txt."                     F9  :  start a debugger (".s:Perl_Debugger.")\n"
  let txt = txt."                 Alt-F9  :  run syntax check          \n"
  let txt = txt."                Ctrl-F9  :  run script                \n"
  let txt = txt."               Shift-F9  :  set command line arguments\n"
	let txt = txt."_________________________________________________________________________\n"
	let	txt = txt." Perl-Support, Version ".g:Perl_Version." / Dr.-Ing. Fritz Mehner / mehner@fh-swf.de\n\n"
	echo txt
endfunction		" ---------- end of function  Perl_Settings  ----------
"
"------------------------------------------------------------------------------
"  run : syntax check
"------------------------------------------------------------------------------
"
let s:Perl_SyntaxCheckMsg       = ""
"
function! Perl_SyntaxCheck ()
	let s:Perl_SyntaxCheckMsg = ""
	exe	":cclose"
	let l:currentdir			= getcwd()
	let	l:currentbuffer   = bufname("%")
	let l:fullname				= l:currentdir."/".l:currentbuffer
	silent exe	":update"
	"
	" avoid filtering the Perl output if the file name does not contain blanks:
	" 
	if match( l:fullname, " " ) < 0
		exe	"set makeprg=perl\\ -cw\\ $*"
		" 
		" Errorformat from compiler/perl.vim (VIM distribution).
		"
		exe ':setlocal errorformat=
		    \%-G%.%#had\ compilation\ errors.,
        \%-G%.%#syntax\ OK,
        \%m\ at\ %f\ line\ %l.,
        \%+A%.%#\ at\ %f\ line\ %l\\,%.%#,
        \%+C%.%#'
	else
		let l:fullname				= escape( l:fullname, s:escfilename )
		"
		" Use tools/efm_perl.pl from the VIM distribution.
		"	This wrapper can handle filenames containing blanks.
		" Errorformat from tools/efm_perl.pl .
		" 
		exe	"set makeprg=".s:root_dir."plugin/efm_perl.pl\\ -c\\ $*"
		exe ':setlocal errorformat=%f:%l:%m'
	endif

	silent exe	":make ".l:fullname

	exe	":botright cwindow"
	exe	':setlocal errorformat='
	exe	"set makeprg=make"
	"
	" message in case of success
	"
	if l:currentbuffer ==  bufname("%")
		let s:Perl_SyntaxCheckMsg = l:currentbuffer." : Syntax is OK"
		return 0
	endif
	return 1
endfunction		" ---------- end of function  Perl_SyntaxCheck  ----------
"
function! Perl_SyntaxCheckMsg ()
		echohl Search 
		echo s:Perl_SyntaxCheckMsg
		echohl None
endfunction		" ---------- end of function  Perl_SyntaxCheckMsg  ----------
"
"----------------------------------------------------------------------
"  run : toggle output destination
"----------------------------------------------------------------------
function! Perl_Toggle_Gvim_Xterm ()

	if has("gui_running")
		if s:Perl_OutputGvim == "vim"
			if has("gui_running")
				exe "aunmenu  <silent>  ".s:Perl_Root.'&Run.&output:\ VIM->buffer->xterm'
				exe "amenu    <silent>  ".s:Perl_Root.'&Run.&output:\ BUFFER->xterm->vim              <C-C>:call Perl_Toggle_Gvim_Xterm()<CR><CR>'
			endif
			let	s:Perl_OutputGvim	= "buffer"
		else
			if s:Perl_OutputGvim == "buffer"
				if has("gui_running")
					exe "aunmenu  <silent>  ".s:Perl_Root.'&Run.&output:\ BUFFER->xterm->vim'
					exe "amenu    <silent>  ".s:Perl_Root.'&Run.&output:\ XTERM->vim->buffer             <C-C>:call Perl_Toggle_Gvim_Xterm()<CR><CR>'
					let	s:Perl_OutputGvim	= "xterm"
				else
					let	s:Perl_OutputGvim	= "vim"
				endif
			else
				" ---------- output : xterm -> gvim
				if has("gui_running")
					exe "aunmenu  <silent>  ".s:Perl_Root.'&Run.&output:\ XTERM->vim->buffer'
					exe "amenu    <silent>  ".s:Perl_Root.'&Run.&output:\ VIM->buffer->xterm            <C-C>:call Perl_Toggle_Gvim_Xterm()<CR><CR>'
				endif
				let	s:Perl_OutputGvim	= "vim"
			endif
		endif
	else
		if s:Perl_OutputGvim == "vim"
			let	s:Perl_OutputGvim	= "buffer"
		else
			let	s:Perl_OutputGvim	= "vim"
		endif
	endif

endfunction    " ----------  end of function Perl_Toggle_Gvim_Xterm  ----------
"
"------------------------------------------------------------------------------
"  run : run
"------------------------------------------------------------------------------
"
let s:Perl_OutputBufferName   = "Perl-Output"
let s:Perl_OutputBufferNumber = -1
"
function! Perl_Run ()
	"
	let	l:currentbuffernr	= bufnr("%")
	let l:currentdir			= getcwd()
	let	l:arguments				= exists("b:Perl_CmdLineArgs") ? " ".b:Perl_CmdLineArgs : ""
	let	l:currentbuffer		= bufname("%")
	let l:fullname				= l:currentdir."/".l:currentbuffer
	" escape whitespaces
	let l:fullname				= escape( l:fullname, s:escfilename )
	"
	silent exe ":update"
	silent exe ":cclose"
	"
	if	s:MSWIN
		let l:arguments	= substitute( l:arguments, '^\s\+', ' ', '' )
		let l:arguments	= substitute( l:arguments, '\s\+', "\" \"", 'g')
	endif
	"
	"------------------------------------------------------------------------------
	"  run : run from the vim command line
	"------------------------------------------------------------------------------
	if s:Perl_OutputGvim == "vim"
		"
		if	s:MSWIN
			exe "!perl \"".l:fullname."\" \"".l:arguments."\""
		else
			exe "!".l:fullname.l:arguments
		endif
		"
	endif
	"
	"------------------------------------------------------------------------------
	"  run : redirect output to an output buffer
	"------------------------------------------------------------------------------
	if s:Perl_OutputGvim == "buffer"
		let	l:currentbuffernr	= bufnr("%")
		if l:currentbuffer ==  bufname("%")
			"
			"
			if bufloaded(s:Perl_OutputBufferName) != 0 && bufwinnr(s:Perl_OutputBufferNumber) != -1 
				exe bufwinnr(s:Perl_OutputBufferNumber) . "wincmd w"
				" buffer number may have changed, e.g. after a 'save as' 
				if bufnr("%") != s:Perl_OutputBufferNumber
					let s:Perl_OutputBufferNumber=bufnr(s:Perl_OutputBufferName)
					exe ":bn ".s:Perl_OutputBufferNumber
				endif
			else
				silent exe ":new ".s:Perl_OutputBufferName
				let s:Perl_OutputBufferNumber=bufnr("%")
				setlocal buftype=nofile
				setlocal noswapfile
				setlocal syntax=none
				setlocal bufhidden=delete
			endif
			"
			" run script 
			"
			setlocal	modifiable
			silent exe ":update"
			if	s:MSWIN
				exe "%!perl \"".l:fullname.l:arguments."\""
			else
				exe "%!".l:fullname.l:arguments
			endif
			setlocal	nomodifiable
			"
			" stdout is empty / not empty
			"
			if line("$")==1 && col("$")==1
				silent	exe ":bdelete"
			else
				if winheight(winnr()) >= line("$")
					exe bufwinnr(l:currentbuffernr) . "wincmd w"
				endif
			endif
		endif
	endif
	"
	"------------------------------------------------------------------------------
	"  run : run in a detached xterm  (not available for MS Windows)
	"------------------------------------------------------------------------------
	if s:Perl_OutputGvim == "xterm"
		"
		if	s:MSWIN
			" same as "vim"
			exe "!perl \"".l:fullname."\" \"".l:arguments."\""
		else
			silent exe '!xterm -title '.l:fullname.' '.s:Perl_XtermDefaults.' -e '.s:root_dir.'plugin/wrapper.sh '.l:fullname.l:arguments
		endif
		"
	endif
	"
endfunction    " ----------  end of function Perl_Run  ----------
"
"------------------------------------------------------------------------------
"  run : start debugger
"------------------------------------------------------------------------------
function! Perl_Debugger ()
	"
	silent exe	":update"
	let	l:arguments	= exists("b:Perl_CmdLineArgs") ? " ".b:Perl_CmdLineArgs : ""
	let	Sou					= escape( expand("%"), s:escfilename ) 
	"
	" debugger is ' perl -d ... '
	"
	if s:Perl_Debugger == "perl"
		if	s:MSWIN
			silent exe "!perl -d \"".Sou.l:arguments."\""
		else
			silent exe "!xterm ".s:Perl_XtermDefaults.' -e perl -d ./'.Sou.l:arguments.' &'
		endif
	endif
	"
	" debugger is 'ptkdb'
	"
	if s:Perl_Debugger == "ptkdb"
		if	s:MSWIN
			silent exe "!perl -d:ptkdb \"".Sou.l:arguments."\""
		else
			silent exe '!perl -d:ptkdb  ./'.Sou.l:arguments.' &'
		endif
	endif
	"
	" debugger is 'ddd'  (not available for MS Windows)
	"
	if s:Perl_Debugger == "ddd" && !s:MSWIN
		silent exe '!ddd ./'.Sou.l:arguments.' &'
	endif
	"
endfunction		" ---------- end of function  Perl_Debugger  ----------
"
"------------------------------------------------------------------------------
"  run : Arguments
"------------------------------------------------------------------------------
function! Perl_Arguments ()
	let filename = escape(expand("%"),s:escfilename)
  if filename == ""
		redraw
		echohl WarningMsg | echo " no file name " | echohl None
		return
  endif
	let	prompt   = 'command line arguments for "'.filename.'" : '
	if exists("b:Perl_CmdLineArgs")
		let	b:Perl_CmdLineArgs= Perl_Input( prompt, b:Perl_CmdLineArgs )
	else
		let	b:Perl_CmdLineArgs= Perl_Input( prompt , "" )
	endif
endfunction		" ---------- end of function  Perl_Arguments  ----------
"
"------------------------------------------------------------------------------
"  run : xterm geometry
"------------------------------------------------------------------------------
function! Perl_XtermSize ()
	let regex	= '-geometry\s\+\d\+x\d\+'
	let geom	= matchstr( s:Perl_XtermDefaults, regex )
	let geom	= matchstr( geom, '\d\+x\d\+' )
	let geom	= substitute( geom, 'x', ' ', "" )
	let	answer= Perl_Input("   xterm size (COLUMNS LINES) : ", geom )
	while match(answer, '^\s*\d\+\s\+\d\+\s*$' ) < 0
		let	answer= Perl_Input(" + xterm size (COLUMNS LINES) : ", geom )
	endwhile
	let answer  = substitute( answer, '^\s\+', "", "" )		 				" remove leading whitespaces
	let answer  = substitute( answer, '\s\+$', "", "" )						" remove trailing whitespaces
	let answer  = substitute( answer, '\s\+', "x", "" )						" replace inner whitespaces
	let s:Perl_XtermDefaults	= substitute( s:Perl_XtermDefaults, regex, "-geometry ".answer , "" )
endfunction		" ---------- end of function  Perl_XtermSize  ----------
"
"------------------------------------------------------------------------------
"  run : make script executable
"------------------------------------------------------------------------------
function! Perl_MakeScriptExecutable ()
	let	filename	= escape( expand("%"), s:escfilename )
	silent exe "!chmod u+x ".filename
	redraw
	if v:shell_error
		echohl WarningMsg
	  echo 'Could not make "'.filename.'" executable !'
	else
		echohl Search
	  echo 'Made "'.filename.'" executable.'
	endif
	echohl None
endfunction		" ---------- end of function  Perl_MakeScriptExecutable  ----------
"
"------------------------------------------------------------------------------
"  run : POD -> html / man / text
"------------------------------------------------------------------------------
function! Perl_POD (arg1)
	let	filename	= escape( expand("%:r"), s:escfilename )
	let	filename	= filename.".".a:arg1
	silent exe	":update"
	silent exe	":!pod2".a:arg1." ".expand("%")." > ".filename
	echo  " '".getcwd()."/".filename."' generated"
endfunction		" ---------- end of function  Perl_POD  ----------
"
"------------------------------------------------------------------------------
"  POD : invisible PODs
"------------------------------------------------------------------------------
function! Perl_InvisiblePOD (arg1)
	let	zz =    "\n=for ".a:arg1.": <keyword>"
	let	zz = zz."\n<single paragraph>\n"
	let	zz = zz."\n=cut  #  back to Perl\n"
	let	zz = zz."\n"
	put =zz
	normal j2W
endfunction		" ---------- end of function  Perl_POD  ----------
"
"------------------------------------------------------------------------------
"  run : perltidy
"------------------------------------------------------------------------------
"
let	s:Perl_perltidy_startscript_executable = 'no'
let	s:Perl_perltidy_module_executable      = 'no'

function! Perl_Perltidy (arg1)

	let	Sou		= expand("%")								" name of the file in the current buffer
	if &filetype != "perl"
		echohl WarningMsg | echo Sou.' seems not to be a Perl file' | echohl None
		return
	endif
	"
	" check if perltidy start script is executable
	" 
	if s:Perl_perltidy_startscript_executable == 'no'
		if !executable("perltidy")
			echohl WarningMsg
			echo 'perltidy does not exist or is not executable!'
			echohl None
			return
		else
			let	s:Perl_perltidy_startscript_executable	= 'yes'
		endif
	endif
	"
	" check if perltidy module is executable 
	" WORKAROUND: after upgrading Perl the module will no longer be found
	" 
	if s:Perl_perltidy_module_executable == 'no'
		let perltidy_version = system("perltidy -v")
		if match( perltidy_version, 'copyright\c' )      >= 0 &&
		\  match( perltidy_version, 'Steve\s\+Hancock' ) >= 0 
			let	s:Perl_perltidy_module_executable	= 'yes'
		else
			echohl WarningMsg
			echo 'The module Perl::Tidy can not be found! Please reinstall perltidy.'
			echohl None
			return
		endif
	endif
	" ----- normal mode ----------------
	if a:arg1=="n"
		if C_Input("reformat whole file [y/n/Esc] : ", "" ) != "y"
			return
		endif
		silent exe	":update"
		let	pos1  = line(".")
		if	s:MSWIN
			silent exe	"%!perltidy"		
		else
			silent exe	"%!perltidy 2>/dev/null"		
		endif
		exe ':'.pos1
		echo "File \"".Sou."\" reformatted."
	endif
	" ----- visual mode ----------------
	if a:arg1=="v"
		let	pos1	= line("'<")
		let	pos2	= line("'>")
		if	s:MSWIN
			silent exe	pos1.",".pos2."!perltidy"
		else
			silent exe	pos1.",".pos2."!perltidy 2>/dev/null"
		endif
		echo "File \"".Sou."\" (lines ".pos1."-".pos2.") reformatted."
	endif
  "
	if filereadable("perltidy.ERR")
		echohl WarningMsg
	  echo 'Perltidy detected an error when processing file "'.Sou.'". Please see file perltidy.ERR' 
		echohl None
	endif
	"
endfunction		" ---------- end of function  Perl_Perltidy  ----------
"
"------------------------------------------------------------------------------
"  run : SmallProf
"------------------------------------------------------------------------------
let	s:Perl_ProfileOutput  	= 'smallprof.out'
let	s:Perl_TimestampFormat 	= '%y%m%d.%H%M%S'
	
function! Perl_Smallprof ()
	let	Sou		= escape( expand("%"), s:escfilename ) " name of the file in the current buffer
	if &filetype != "perl"
		echohl WarningMsg | echo Sou.' seems not to be a Perl file' | echohl None
		return
	endif
	silent exe	":update"
	"
	echohl Search | echo ' ... profiling ... ' | echohl None
	silent exe	"!perl -d:SmallProf ".Sou
	"
	if v:shell_error
		echohl WarningMsg | echo 'Could not execute "perl -d:SmallProf '.Sou.'"' | echohl None
	else
		"
		let currentbuffer	= s:Perl_ProfileOutput
		if s:Perl_ProfilerTimestamp=="yes"
			let currentbuffer=currentbuffer.".".strftime(s:Perl_TimestampFormat)
			call rename( s:Perl_ProfileOutput, currentbuffer )
		endif
		echohl Search | echo 'file "'.Sou.'" profiled' | echohl None
		if filereadable(currentbuffer) 
			let currentbuffernr=bufnr(currentbuffer)
			if currentbuffernr==-1          " buffer not open
				exe	":botright new"
				exe	":edit +set\\ autoread ".currentbuffer
			else
				if bufwinnr(currentbuffernr)!=-1		" window open ?
					exe  bufwinnr(currentbuffernr) . "wincmd w"
				else
					:botright new
					exe ":buffer ".currentbuffer
				endif
			endif
			normal gg
		else
			echohl WarningMsg | echo currentbuffer.' (profiling results) not readable!' | echohl None
		endif
	endif
endfunction		" ---------- end of function  Perl_Smallprof  ----------
"
"------------------------------------------------------------------------------
"  run : Save buffer with timestamp
"------------------------------------------------------------------------------
function! Perl_SaveWithTimestamp ()
  if expand("%") == ""
		redraw
		echohl WarningMsg | echo " no file name " | echohl None
		return
  endif
	let	Sou		= escape( expand("%"), s:escfilename ) " name of the file in the current buffer
	let	Sou	 	= Sou.".".strftime(s:Perl_TimestampFormat)
	silent exe ":write ".Sou
	echomsg 'file "'.Sou.'" written'
endfunction		" ---------- end of function  Perl_SaveWithTimestamp  ----------
"
"------------------------------------------------------------------------------
"  run : hardcopy
"    MSWIN : a printer dialog is displayed
"    other : print PostScript to file
"------------------------------------------------------------------------------
function! Perl_Hardcopy (arg1)
	let Sou	= expand("%")	
  if Sou == ""
		redraw
		echohl WarningMsg | echo " no file name " | echohl None
		return
  endif
	let target	= bufname("%")==s:Perl_PerldocBufferName ? '$HOME/' : './'
	let	Sou			= target.expand("%")
	" ----- normal mode ----------------
	if a:arg1=="n"
		silent exe	"hardcopy > ".Sou.".ps"		
		if	!s:MSWIN
			echo "file \"".Sou."\" printed to \"".Sou.".ps\""
		endif
	endif
	" ----- visual mode ----------------
	if a:arg1=="v"
		silent exe	"*hardcopy > ".Sou.".ps"		
		if	!s:MSWIN
			echo "file \"".Sou."\" (lines ".line("'<")."-".line("'>").") printed to \"".Sou.".ps\""
		endif
	endif
endfunction		" ---------- end of function  Perl_Hardcopy  ----------
"

"------------------------------------------------------------------------------
"	 Create the load/unload entry in the GVIM tool menu, depending on 
"	 which script is already loaded
"------------------------------------------------------------------------------
function! Perl_CreateUnLoadMenuEntries ()
	"
	" Perl is now active and was former inactive -> 
	" Insert Tools.Unload and remove Tools.Load Menu
	" protect the following submenu names against interpolation by using single qoutes (Mn)
	"
	if  s:Perl_Active == 1
		:aunmenu &Tools.Load\ Perl\ Support
		exe 'amenu  <silent> 40.1160   &Tools.Unload\ Perl\ Support  	<C-C>:call Perl_Handle()<CR>'
	else
		" Perl is now inactive and was former active or in initial state -1 
		if s:Perl_Active == 0
			" Remove Tools.Unload if Perl was former inactive
			:aunmenu &Tools.Unload\ Perl\ Support
		else
			" Set initial state Perl_Active=-1 to inactive state Perl_Active=0
			" This protects from removing Tools.Unload during initialization after
			" loading this script
			let s:Perl_Active = 0
			" Insert Tools.Load
		endif
		exe 'amenu <silent> 40.1000 &Tools.-SEP100- : '
		exe 'amenu <silent> 40.1160 &Tools.Load\ Perl\ Support <C-C>:call Perl_Handle()<CR>'
	endif
	"
endfunction		" ---------- end of function  Perl_CreateUnLoadMenuEntries  ----------
"
"------------------------------------------------------------------------------
"  Loads or unloads Perl extensions menus
"------------------------------------------------------------------------------
function! Perl_Handle ()
	if s:Perl_Active == 0
		:call Perl_InitMenu()
		let s:Perl_Active = 1
	else
		if has("gui_running")
			if s:Perl_Root == ""
				aunmenu Comments
				aunmenu Statements
				aunmenu Idioms
				aunmenu Regex
				aunmenu CharCls
				aunmenu File-Tests
				aunmenu Spec-Var
				aunmenu POD
				aunmenu Run
			else
				exe "aunmenu ".s:Perl_Root
			endif
		endif

		let s:Perl_Active = 0
	endif

	call Perl_CreateUnLoadMenuEntries ()
endfunction		" ---------- end of function Perl_Handle   ----------
"
"------------------------------------------------------------------------------
" 
call Perl_CreateUnLoadMenuEntries()			" create the menu entry in the GVIM tool menu
if s:Perl_LoadMenus == "yes"
	call Perl_Handle()										" load the menus
endif
"
"------------------------------------------------------------------------------
"  Automated header insertion
"------------------------------------------------------------------------------
if has("autocmd")
	" 
	" =====  Perl-script : insert header, write file, make it executable  =============
	if s:MSWIN
		autocmd BufNewFile  *.pl  call Perl_CommentTemplates('header') | :w! 
	else
		autocmd BufNewFile  *.pl  call Perl_CommentTemplates('header') | :w! | call Perl_MakeScriptExecutable()
	endif
	" 
	" =====  Perl module : insert header, write file  =================================
	autocmd BufNewFile  *.pm  call Perl_CommentTemplates('module') | :w!
	" 
	" =====  Perl POD module : set filetype to Perl  ==================================
	autocmd BufNewFile,BufRead *.pod  set filetype=perl
	"
endif " has("autocmd")
"
"------------------------------------------------------------------------------
"  Key mappings : show / hide the perl-support menus
"------------------------------------------------------------------------------
nmap    <silent>  <Leader>lps             :call Perl_Handle()<CR>
nmap    <silent>  <Leader>ups             :call Perl_Handle()<CR>
"
"
" vim:set tabstop=2: 
