" Name:         Gitewer.vim
" Description:  vim plugin as Git-Viewer.
" Author:       MeF

let s:bufs = {}

function! s:is_git_repo() abort
    let git_path = finddir('.git', '.;')
    if empty(git_path)
        echohl WarningMsg
        echo 'not a git repository'
        echohl None
        return v:false
    else
        return v:true
    endif
endfunction

function! s:is_already_opened(name) abort
    for wnr in range(1, winnr('$'))
        if bufname(winbufnr(wnr)) =~# printf('gitewer:%s', a:name)
            return v:true
        endif
    endfor
    return v:false
endfunction

" function! s:is_hash(hash) abort
"     if match(a:hash, '[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]\+') == 0
"         return v:true
"     else
"         return v:false
"     endif
" endfunction

function! s:show_help() abort
    echo 'usage; :Gitewer command [options]'
    echo "\n"
    echo 'commands and available options:'
    echo '  log [dir/file [dir/file ...]]'
    echo "\t show commit logs"
    echo '  status'
    echo "\t show working-tree status"
    echo '  show [file/dir/hash [file/dir/hash ...]]'
    echo "\t show various types of objects"
    echo '  diff [file] [hash1] [hash2]'
    echo "\t show changes between the file in current status and that in hash1, or the file in hash1 and that in hash2. default: file=current file, hash1=HEAD, hash2=nothing"
    echo '  blame'
    echo "\t show what revision and author last modified each line of a current file"
    echo '  stash'
    echo "\t show the changes recorded in the stash as a diff"
    echo '  grep [opt [opt2 ...]] <word>'
    echo "\t execute git grep and show the results in the quickfix window."
    echo "\t there are 2 special opts; '--all_branches' and '--all_commits'."
    echo '  log-file'
    echo "\t show file names edited in each commit."
endfunction

let s:load_git_syntax = 0
function! <SID>buf_create(mod, width, name, text_list) abort
    if match(keys(s:bufs), printf('^%s$', a:name)) == -1
        let s:bufs[a:name] = 1
    else
        let s:bufs[a:name] += 1
        if s:bufs[a:name] > 5
            let s:bufs[a:name] = 1
        endif
    endif
    let name = printf('gitewer:%s-%d', a:name, s:bufs[a:name])
    execute printf('%s %snew %s', a:mod, a:width, name)

    setlocal modifiable
    silent %delete _
    setlocal noreadonly
    setlocal noswapfile
    setlocal nobackup
    setlocal noundofile
    setlocal buftype=nofile
    setlocal nobuflisted
    setlocal nowrap
    setlocal foldlevel=9999
    setlocal report=9999
    setlocal winfixwidth
    setlocal nolist

    call append(0, a:text_list)
    normal! gg
    if !s:load_git_syntax
        runtime! syntax/git.vim
        let s:load_git_syntax = 1
    endif
endfunction

function! <SID>get_hash() abort
    let line = getline('.')
    let idx = match(line, '[0-9a-f]\{6}')
    if idx == -1
        return ''
    else
        let hash = line[idx:idx+6]
        return hash
    endif
endfunction

function! s:expand_args(arg_list) abort
    return map(a:arg_list, 'expand(v:val)')
endfunction

function! s:set_period() abort
    let period_opt = get(g:, 'gitewer_set_period', 100)
    if period_opt ==# 'all'
        let s:period = []
    elseif type(period_opt) == type(0)
        let s:period = ['-n', period_opt]
    elseif type(period_opt) == type('')
        let s:period = ['--since', period_opt]
    else
        let s:period = ['-n', '100']
    endif
endfunction

function! gitewer#gitewer(mod, ...) abort
    if !s:is_git_repo()
        return
    endif

    call s:set_period()

    if a:1 == 'help'
        call s:show_help()
    elseif a:1 == 'status'
        call call('gitewer#status', [a:mod]+s:expand_args(a:000[1:]))
    elseif a:1 == 'log'
        call call('gitewer#log', [a:mod]+s:expand_args(a:000[1:]))
    elseif a:1 == 'show'
        call call('gitewer#show', [a:mod]+s:expand_args(a:000[1:]))
    elseif a:1 == 'diff'
        if a:0 == 1
            " no suboption
            let file = expand('%')
            let hash1 = ''
            let hash2 = 'HEAD'
        elseif a:0 == 2
            if filereadable(a:2)
                " file specified
                let file = a:2
                let hash1 = ''
                let hash2 = 'HEAD'
            else
                " hash specified
                let file = expand('%')
                let hash1 = ''
                let hash2 = a:2
            endif
        elseif a:0 == 3
            if filereadable(a:2)
                " fike & hash
                let file = a:2
                let hash1 = ''
                let hash2 = a:3
            else
                " hashes
                let file = expand('%')
                let hash1 = a:2
                let hash2 = a:3
            endif
        elseif a:0 == 4
            " file, hash1, hash2
            let file = a:2
            let hash1 = a:3
            let hash2 = a:4
        else
            echohl WarningMsg
            echo "Invalid arguments"
            echohl None
            return
        endif
        call gitewer#diff(file, hash1, hash2)
    elseif a:1 == 'blame'
        call gitewer#blame(a:mod)
    elseif a:1 == 'stash'
        call gitewer#stash(a:mod)
    elseif a:1 == 'grep'
        call call("gitewer#grep", a:000[1:])
    elseif a:1 == 'log-file'
        call gitewer#log_file(a:mod)
    else
        " if get(g:, 'gitewer_anyargs', 0)
        "     call gitewer#any(a:mod)
        " endif
        echohl WarningMsg
        echo "incorrect subcommand."
        echohl None
    endif
endfunction

function! gitewer#log(mod, ...) abort
    if !s:is_git_repo()
        return
    endif

    if has('nvim')
        let log_cmd = ['git', 'log', '--graph', '--pretty=format:%h %aI; (%an)%d:| %s'] + s:period
        let log_cmd += a:000
    else
        let log_cmd = ['git', 'log', '--graph', '--pretty="format:%h %aI; (%an)%d:| %s"'] + s:period
        let log_cmd += a:000
        let log_cmd = join(log_cmd, ' ')
    endif
    let res = systemlist(log_cmd)
    if empty(a:mod)
        let mod = 'tab'
    else
        let mod = a:mod
    endif
    call <SID>buf_create(mod, '', 'log', res)
    call s:log_syntax()
    setlocal nomodifiable
    let b:gitewer_log_opt = a:000
    nnoremap <buffer> <silent> <Enter> <Cmd>call <SID>show_preview(<SID>get_hash())<CR>
    nnoremap <buffer> <silent> d <Cmd>call <SID>show_diff(<SID>get_hash())<CR>
endfunction

function gitewer#log_file(mod) abort
    if !s:is_git_repo()
        return
    endif

        let log_cmd = ['git', 'log', '--name-only', '--oneline'] + s:period
    if !has('nvim')
        let log_cmd = join(log_cmd, ' ')
    endif
    let res = systemlist(log_cmd)
    if empty(a:mod)
        let mod = 'tab'
    else
        let mod = a:mod
    endif
    call <SID>buf_create(mod, '', 'log-name', res)
    call s:logfile_syntax()
    setlocal nomodifiable
    let b:gitewer_log_opt = []
    nnoremap <buffer> <silent> <Enter> <Cmd>call <SID>show_preview(<SID>get_hash())<CR>
    nnoremap <buffer> <silent> d <Cmd>call <SID>show_diff(<SID>get_hash())<CR>
endfunction


function! gitewer#show(mod, ...) abort
    if !s:is_git_repo()
        return
    endif

    let show_cmd = ['git', 'show']+a:000
    if !has('nvim')
        let show_cmd = join(show_cmd, ' ')
    endif
    let res = systemlist(show_cmd)
    let opt = join(map(deepcopy(a:000), 'substitute(v:val, "/", "-", "g")'), ',')

    if empty(a:mod)
        let mod = 'tab'
    else
        let mod = a:mod
    endif
    call <SID>buf_create(mod, '', 'show:'..opt, res)
    call s:show_syntax()
    setlocal nomodifiable
endfunction

function! <SID>show_preview(hash) abort
    if empty(a:hash)
        return
    endif
    pclose
    let opt = get(b:, 'gitewer_log_opt', [])
    call call('gitewer#show', ['topleft', a:hash]+opt)
    setlocal previewwindow
endfunction

function! <SID>show_diff(hash) abort
    if empty(a:hash)
        return
    endif

    let opt = get(b:, 'gitewer_log_opt', [])
    let cmd = ['git', 'diff', 'HEAD', a:hash] + opt
    if !has('nvim')
        let cmd = join(cmd, ' ')
    endif
    let res = systemlist(cmd)
    call s:buf_create('topleft', '', 'diff-show', res)
    call s:show_syntax()
    setlocal nomodifiable
endfunction

function! gitewer#status(mod, ...) abort
    if !s:is_git_repo()
        return
    endif

    let status_cmd = ['git', 'status', '-sbuall']   " short & branch & show all untracked files
    let status_cmd += a:000
    if !has('nvim')
        let status_cmd = join(status_cmd, ' ')
    endif
    let res = systemlist(status_cmd)
    let res[0] = substitute(res[0], '##', 'branch:', '')
    let no_files = 0
    if len(res)==1
        call add(res, '')
        call add(res, 'no committed or modified files')
        let no_files = 1
    endif
    if empty(a:mod)
        let mod = 'topleft'
    else
        let mod = a:mod
    endif
    call <SID>buf_create(mod, '', 'status', res)
    setlocal nomodifiable
    call s:status_syntax(!no_files)
    if !no_files
        nnoremap <buffer> <silent> <Enter> <Cmd>call <SID>show_file_status()<CR>
    endif
endfunction

function! s:show_file_status() abort
    if line('.') == 1
        return
    endif
    let fname = getline('.')[3:]
    if !filereadable(fname)
        echo printf('%s is not found.', fname)
        return
    endif

    pclose
    if getline('.')[0] ==# 'M'
        " staged
        let diff_cmd = ['git', 'diff', '--cached', fname]
    else
        " not staged
        let diff_cmd = ['git', 'diff', fname]
    endif
    if !has('nvim')
        let diff_cmd = join(diff_cmd, ' ')
    endif
    let res = systemlist(diff_cmd)
    if !empty(res)
        call <SID>buf_create('botright vertical', '', 'status_detail', res)
        call s:show_syntax()
        setlocal nomodifiable
    else
        " untracked file?
        execute 'botright vertical new '..fname
    endif
    setlocal previewwindow
endfunction

function! gitewer#diff(file, hash1, hash2) abort
    if !s:is_git_repo()
        return
    endif
    if !filereadable(a:file)
        echohl WarningMsg
        echo 'please open a file.'
        echohl None
        return
    endif
    let buf_name = printf('diff:%s-%s', a:file, a:hash1)
    if s:is_already_opened(buf_name)
        echohl WarningMsg
        echo 'already opened'
        echohl None
        return
    endif

    if !empty(a:hash1)
        let diff_cmd = ['git', 'show', printf('%s:%s', a:hash1, a:file)]
        if !has('nvim')
            let diff_cmd = join(diff_cmd, ' ')
        endif
        let res = systemlist(diff_cmd)
        call <SID>buf_create('tab', '', buf_name, res)
        $delete _
        setlocal nomodifiable
    elseif a:file != expand('%')
        execute 'tabnew '..a:file
    endif
    let ft = &filetype

    let diff_cmd = ['git', 'show', printf('%s:%s', a:hash2, a:file)]
    if !has('nvim')
        let diff_cmd = join(diff_cmd, ' ')
    endif
    let res = systemlist(diff_cmd)
    call <SID>buf_create('vertical', '', printf('diff:%s-%s', a:file, a:hash2), res)
    let &filetype = ft
    $delete _
    diffthis
    setlocal nomodifiable
    wincmd p
    diffthis
endfunction

function! gitewer#blame(mod) abort
    if !s:is_git_repo()
        return
    endif
    let fname = expand('%')
    if !filereadable(fname)
        echohl WarningMsg
        echo 'please open a file.'
        echohl None
        return
    endif
    let buf_name = 'blame'
    if s:is_already_opened(buf_name)
        echohl WarningMsg
        echo 'already opened'
        echohl None
        return
    endif

    let winID = win_getid()
    let pre_opt = 'setlocal noscrollbind'
    if &wrap
        let pre_opt .= ' | setlocal wrap'
    endif
    let pre_opt .= ' | setlocal nocursorbind'
    let blame_cmd = ['git', 'blame', fname]
    let lnum = line('.')
    normal! gg
    if !has('nvim')
        let blame_cmd = join(blame_cmd, ' ')
    endif
    let res = systemlist(blame_cmd)
    let res = map(res, "v:val[:stridx(v:val, ')')]")
    call <SID>buf_create('topleft vertical', 35, buf_name, res)
    $delete _
    normal! gg
    setlocal scrollbind
    setlocal cursorbind
    setlocal winfixwidth
    setlocal nonumber
    setlocal nomodifiable
    let b:gitewer_log_opt = [fname]
    nnoremap <buffer> <silent> <Enter> <Cmd>call <SID>show_preview(<SID>get_hash())<CR>
    nnoremap <buffer> <silent> d <Cmd>call <SID>show_diff(<SID>get_hash())<CR>
    call s:blame_syntax()
    execute printf("autocmd Gitewer WinClosed <buffer> ++once call win_execute(%d, '%s')", winID, pre_opt)
    wincmd p
    setlocal scrollbind
    setlocal cursorbind
    setlocal nowrap
    execute lnum
endfunction

function! gitewer#stash(mod) abort
    if !s:is_git_repo()
        return
    endif

    let stash_list_cmd = ['git', 'stash', 'list']
    if !has('nvim')
        let stash_list_cmd = join(stash_list_cmd, ' ')
    endif
    let res = systemlist(stash_list_cmd)
    if len(res) == 0
        echo 'no stash found.'
        return
    endif

    let in_str = ""
    for i in range(len(res))
        let in_str .= printf('%d: ', i+1)
        let in_str .= res[i][stridx(res[i], ':')+2:]
        let in_str .= "\n"
    endfor
    let in_str .= repeat("\n", &cmdheight-len(res))
    let in_str .= "select stash (empty cancel); "
    let stash = input(in_str)
    if empty(stash)
        return
    endif
    let stash = str2nr(stash)-1
    if stash<0 || stash>=len(res)
        echo "\n"
        echohl ErrorMsg
        echo 'invalid number'
        echohl None
        return
    endif
    let stash_cmd = ['git', 'stash', 'show', '-p', 'stash@{'.stash.'}']
    if !has('nvim')
        let stash_cmd = join(stash_cmd, ' ')
    endif
    let res = systemlist(stash_cmd)
    if empty(a:mod)
        let mod = 'tab'
    else
        let mod = a:mod
    endif
    call <SID>buf_create(mod, '', 'stash', res)
    call s:stash_syntax()
    setlocal nomodifiable
endfunction

function! gitewer#grep(...) abort
    if empty(a:000)
        echohl ErrorMsg
        echo "search word is required"
        echohl None
        return
    endif
    if a:1 ==# '--all_branches'
        let word = a:2
        if !has('nvim')
            let bra_cmd = 'git branch -a --format="%(objectname) %(refname:short)"'
        else
            let bra_cmd = ['git', 'branch', '-a', '--format=%(objectname) %(refname:short)']
        endif
        let opt = systemlist(bra_cmd)
        let opt = map(uniq(sort(opt)), 'v:val[41:]')
        let grep_cmd = ['git', 'grep', '-n', word]+opt
    elseif a:1 ==# '--all_commits'
        let word = a:2
        let hash_cmd = ['git', 'rev-list', '--all', '--max-count=50']
        if !has('nvim')
            let hash_cmd = join(hash_cmd, ' ')
        endif
        let opt = systemlist(hash_cmd)
        let opt = map(opt, 'v:val[:5]')
        let grep_cmd = ['git', 'grep', '-n', word]+opt
    else
        let grep_cmd = ['git', 'grep', '-n']+a:000
    endif

    if !has('nvim')
        let grep_cmd = join(grep_cmd, ' ')
    endif

    " echo grep_cmd
    let grep_list = systemlist(grep_cmd)
    if empty(grep_list)
        echohl WarningMsg
        echo 'no hits'
        echohl None
        return
    else
        cgetexpr grep_list
        cwindow
    endif
endfunction

function! s:gitewer_highlight() abort
    if &background == 'dark'
        highlight default GitewerCol1 guifg=Red ctermfg=9
        highlight default GitewerCol2 guifg=Green ctermfg=10
        highlight default GitewerCol3 guifg=Magenta ctermfg=13
        highlight default GitewerCol4 guifg=Silver ctermfg=7
        highlight default GitewerCol5 guifg=Gold ctermfg=220
        highlight default GitewerCommit guifg=Silver ctermfg=7
        highlight default GitewerUntracked guifg=Silver ctermfg=7
        highlight default GitewerIgnored guifg=Grey30 ctermfg=239
        highlight default GitewerUnstaged guifg=Red ctermfg=9
        highlight default GitewerStaged guifg=Lime ctermfg=10
        highlight default GitewerHash guifg=Yellow ctermfg=11
    else
        highlight default GitewerCol1 guifg=Red ctermfg=9
        highlight default GitewerCol2 guifg=Green ctermfg=10
        highlight default GitewerCol3 guifg=Magenta ctermfg=13
        highlight default GitewerCol4 guifg=Silver ctermfg=7
        highlight default GitewerCol5 guifg=Gold ctermfg=220
        highlight default GitewerCommit guifg=#767676 ctermfg=243
        highlight default GitewerUntracked guifg=Silver ctermfg=7
        highlight default GitewerIgnored guifg=Grey70 ctermfg=249
        highlight default GitewerUnstaged guifg=Red ctermfg=9
        highlight default GitewerStaged guifg=Green ctermfg=10
        highlight default GitewerHash guifg=DarkYellow ctermfg=3
    endif
    highlight default link GitewerAuthor gitIdentity
    highlight default link GitewerDate gitDate
    highlight default link GitewerFile diffFile
    highlight default link GitewerBranch Title
    " highlight default link GitewerAdd diffAdded
    " highlight default link GitewerDelete diffRemoved
endfunction

call s:gitewer_highlight()
augroup Gitewer
    autocmd!
    autocmd ColorScheme * call s:gitewer_highlight()
augroup END

function! s:log_graph_syntax() abort
    let idx_cnt = 1
    let idx_max = 5
    let log_match = {'1-0': idx_cnt}
    call matchaddpos('GitewerCol'.log_match['1-0'], [[1,1]])

    for i in range(2, line('$'))
        let line = getline(i)
        let end = match(line, '[0-9a-f]')-1
        if end < 0
            let end = len(line)-1
        endif
        let pos = {}
        for j in range(1, idx_max)
            let pos[printf('%d', j)] = []
        endfor
        for j in range(0, end)
            if line[j] =~# '\s'
                continue
            elseif line[j] =~# '[|*]'
                let pre_line = getline(i-1)
                if pre_line[j-1:j] == '\|'
                    let idx_cnt = (idx_cnt%idx_max)+1
                    let log_match[i.'-'.j] = idx_cnt
                elseif pre_line[j] =~# '[|*]'
                    let log_match[i.'-'.j] = log_match[(i-1).'-'.j]
                elseif pre_line[j-1] == '\'
                    let log_match[i.'-'.j] = log_match[(i-1).'-'.(j-1)]
                elseif pre_line[j+1] == '/'
                    let log_match[i.'-'.j] = log_match[(i-1).'-'.(j+1)]
                endif
            elseif line[j] == '/'
                let pre_line = getline(i-1)
                if pre_line[j+1] == '/'
                    let log_match[i.'-'.j] = log_match[(i-1).'-'.(j+1)]
                elseif pre_line[j+2] == '/'
                    let log_match[i.'-'.j] = log_match[(i-1).'-'.(j+2)]
                elseif pre_line[j+1] =~# '[|*]'
                    let log_match[i.'-'.j] = log_match[(i-1).'-'.(j+1)]
                elseif pre_line[j] == '\'
                    let log_match[i.'-'.j] = log_match[(i-1).'-'.(j)]
                endif
            elseif line[j] == '\'
                if line[j+1] == '|'
                    let log_match[i.'-'.j] = log_match[(i-1).'-'.(j+1)]
                elseif line[j-1] =~# '[|*]'
                    " new line
                    let idx_cnt = (idx_cnt%idx_max)+1
                    " let idx_cnt = (log_match[i.'-'.(j-1)]%idx_max)+1
                    let log_match[i.'-'.j] = idx_cnt
                else
                    let log_match[i.'-'.j] = log_match[(i-1).'-'.(j-1)]
                endif
            endif
            if has_key(log_match, i.'-'.j)
                call add(pos[log_match[i.'-'.j]], [i, j+1])
            endif
        endfor
        for id in keys(pos)
            if !empty(pos[id])
                call matchaddpos('GitewerCol'.id, pos[id])
            endif
        endfor
    endfor
endfunction

function! s:log_syntax() abort
    if getline(1)[0] !=# '*'
        " failed to get the log.
        return
    endif
    " syntax match GitewerOpts "^|[ |\\/]* " contains=
    "             \ GitewerAuthor, GitewerDate,
    "             \ GitewerCol1, GitewerCol2, GitewerCol3
    syntax match GitewerOpts /^.*:| / contains=
                \ GitewerAuthor, GitewerDate, GitewerCommit
                " \ GitewerCol1, GitewerCol2, GitewerCol3
    if 0
        for i in range(10)
            let bias = ''
            let col_idx = i%3+1
            let shift1 = 2*i+1
            let shift2 = 2*i
            execute 'syntax match GitewerCol'.col_idx.' "\%'.shift1.'v\zs[|\*\\/]\ze" contained'
            execute 'syntax match GitewerCol'.col_idx.' "\%'.shift2.'v\zs[\\/]\ze" contained'
        endfor
    else
        call s:log_graph_syntax()
    endif
    syntax region GitewerAuthor start=/; (\zs/ end=/\ze)\( (\|:\)/ contained
    syntax region GitewerDate start=/[12][0-9][0-9][0-9]-/ end=/\([+-][01][0-9]:[0-9][0-9]\|Z\)\ze; / contained
    syntax region GitewerCommit start=/) \zs(/ end=/)\ze:/ contained
    " syntax match GitewerHash /^.* \zs[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]\ze/
endfunction

function! s:logfile_syntax() abort
    syntax match GitewerHash /^\zs[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]\ze/
endfunction

function! s:show_syntax() abort
    set filetype=git
    " syntax match GitewerCommit /^commit [0-9a-f]*/
    " syntax match GitewerAuthor /^Author: .*/
    " syntax match GitewerDate   /^Date: .*/
    " syntax match GitewerAdd    /^+.*/
    " syntax match GitewerDelete /^-.*/
    " syntax match GitewerFile   /^@@ .*/
endfunction

function! s:status_syntax(all) abort
    " https://git-scm.com/docs/git-status#_short_format
    call matchaddpos('GitewerBranch', [1])
    if !a:all
        return
    endif
    syntax match GitewerUntracked /^??/
    syntax match GitewerIgnored /^!!/
    for i in range(2, line('$')-1)
        let line = getline(i)
        if empty(line)
            continue
        endif
        if line[:1] == '!!'
            continue
        endif
        if line[:1] == '??'
            continue
        endif
        call matchaddpos('GitewerStaged', [[i,1]])
        call matchaddpos('GitewerUnstaged', [[i,2]])
    endfor
endfunction

function! s:blame_syntax() abort
    syntax match GitewerFile /[0-9a-f]\+ \zs\S*\ze \+(/
    syntax match GitewerDate /\zs[12][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9] \S\+\ze.*/
    syntax match GitewerAuthor /(\zs.*\ze[12][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9] \S\+.*)/
endfunction

function! s:stash_syntax() abort
    set filetype=git
    " syntax match GitewerAdd    /^+.*/
    " syntax match GitewerDelete /^-.*/
    " syntax match GitewerFile   /^@@ .*/
endfunction

