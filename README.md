# myConfig
My useful configuration files.

## Bash

### [`bashrc.sh`](bash/bashrc.sh)

It modifies the PS1 variable, sets aliases, configures the auto-completion and defines the following functions:
  - `files $1`: count the number of files/directories/links in the current folder (no $1) or in a given folder ($1).
  - `up $1`: jump to X many parent directories (1 without $1).
  - `extract $1`: extract a given archive ($1) with the right tool and/or options.
  - `transfer $1 $2`: transfer a file/folder from a location ($1) to another ($2) using a double rsync (it checks md5 and removes source).

**Installation**: add `source $somePath/myConfig/bash/bashrc.sh` at the end of your `~/.bashrc`.