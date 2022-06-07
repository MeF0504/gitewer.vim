" Name:         Gitewer.vim
" Description:  vim plugin as Git-Viewer.
" Author:       MeF

if exists('g:loaded_gitewer')
    finish
endif
let g:loaded_gitewer = 1

if !executable('git')
    echohl ErrorMsg
    echo 'git is not executable. Gitewer is not loaded.'
    echohl None
endif

function! s:get_files(arg) abort
    return split(glob(a:arg..'*'), '\n')
endfunction

function! s:get_hashes(arg) abort
    let hash_cmd = ['git', 'log', '--pretty=format:%h', '-'..get(g:, 'gitewer_hist_size', 100)]
    if !has('nvim')
        let hash_cmd = join(hash_cmd, ' ')
    endif
    let hashes = systemlist(hash_cmd)
    let hashes = ['HEAD', 'HEAD^', 'HEAD^^'] + hashes
    return filter(hashes, '!stridx(v:val, a:arg)')
endfunction

function! s:gitewer_comp(arglead, cmdline, cursorpos) abort
    let arglead = tolower(a:arglead)
    let cmdline = tolower(a:cmdline)
    let opts = split('help log show status diff blame stash', ' ')
    let cmdlines = split(cmdline, ' ', 1)
    let gi_idx = match(cmdlines, 'G.*')
    if len(cmdlines) <= gi_idx+2
        return filter(opts, 'match(cmdline, v:val)==-1 && !stridx(tolower(v:val), arglead)')
    else
        let cur_opt = cmdlines[gi_idx+1]
        if cur_opt == 'help'
            return []
        elseif cur_opt == 'log'
            return s:get_files(a:arglead)
        elseif cur_opt == 'show'
            return s:get_files(a:arglead)+filter(s:get_hashes(a:arglead), 'match(a:cmdline, v:val)==-1')
        elseif cur_opt == 'diff'
            if len(cmdlines) == gi_idx+3
                return s:get_files(a:arglead)+filter(s:get_hashes(a:arglead), 'match(a:cmdline, v:val)==-1')
            elseif len(cmdlines) == gi_idx+4
                return filter(s:get_hashes(a:arglead), 'match(a:cmdline, v:val)==-1')
            elseif len(cmdlines) == gi_idx+5
                return filter(s:get_hashes(a:arglead), 'match(a:cmdline, v:val)==-1')
            else
                return []
            endif
        elseif cur_opt == 'blame'
            return []
        endif
    endif
endfunction

command! -nargs=+ -complete=customlist,s:gitewer_comp Gitewer call gitewer#gitewer(<q-mods>, <f-args>)

