# Git-Viewer = Gitewer.vim

Vim plugin to only watch, not control the status of git.

## Requirements

`git` command.
```vim
echo executable('git') " = 1
```

## Installation

If you use dein,
```vim
call dein#add('MeF0504/gitewer.vim')
```
or do something like this.

## Usage
``` vim
:Gitewer command [options]
```

commands and available options:

- help
    - show help strings.
- log [dir/file [dir/file ...]];
    - show commit logs
- status [dir/file [dir/file ...]];
    - show working-tree status
- show [file/dir/hash]
    - show various types of objects
- diff [file] [hash1] [hash2]
    - show changes between the file in current status and that in hash1, or the file in hash1 and that in hash2. default: file=current file, hash1=HEAD, hash2=nothing
- blame
    - show what revision and author last modified each line of a current file
- stash
    - show the changes recorded in the stash as a diff
- grep [opt [opt2 ...]] <word>
    - execute git grep and show the results in the quickfix window.
      there are 2 special opts; '--all_branches' and '--all_commits'.
- log-file
    - show file names edited in each commit.

## Options

- `g:gitewer_set_period` : specify the log period shown in this plugin.
If the type of this variable is number, `-n <num>` option is used in the git command.
If that is a string, `--since ` is used.
If 'all' is set, do not limit the log period.
default:100.
- highlight color
    - `GitewerAuthor`    : highlight color mainly for author line.
    - `GitewerDate`      : highlight color mainly for date line.
    - `GitewerCol1`      : highlight color for first column of git log page. `GitewerCol2`, `GitewerCol3` are also available.
    - `GitewerCommit`    : highlight color mainly for commit logs.
    - `GitewerFile`      : highlight color mainly for file line.
    - `GitewerAdd`       : highlight color for added lines.
    - `GitewerDelete`    : highlight color for deleted lines.
    - `GitewerUntracked` : highlight color for a untracked mark.
    - `GitewerIgnored`   : highlight color for a ignored mark.
    - `GitewerUnstaged`  : highlight color for a character of "unstaged" column of short status.
    - `GitewerStaged`    : highlight color for a character of "staged" column of short status.
    - `GitewerHash`      : highlight color for hash number in `log-file` command.

