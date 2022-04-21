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

## Options

- `g:gitewer_hist_size`: specify the size of log history showing in this plugin. default:100.
- highlight color
    - `GitewerAuthor`: highlight color mainly for author line.
    - `GitewerDate`  : highlight color mainly for date line.
    - `GitewerCol1`  : highlight color for first column of git log page. `GitewerCol2`, `GitewerCol3` are also available.
    - `GitewerCommit`: highlight color mainly for commit logs.
    - `GitewerFile`  : highlight color mainly for file line.
    - `GitewerAdd`   : highlight color for added lines.
    - `GitewerDelete`: highlight color for deleted lines.

