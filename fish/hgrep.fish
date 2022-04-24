#!/usr/bin/env fish

set -l PROG = 'hgrep.fish'
# ref: https://fishshell.com/docs/current/cmds/argparse.html#cmd-argparse
set -l options 'C/context=' 'h/help'

function usage -S -d "basic usage for $PROG"
    echo \
"Usage: $PROG [-C|--context context] <SEARCH> [<INPUT PATH>]"
end

# parse args here
argparse $options -- $argv

set -l argc (count $argv)
# note: processed arguments are removed from $argv
if test $argc -ne 1 -a $argc -ne 2
    usage
    exit 0
end

set -l search_string $argv[1] # first argument
set -l input_path /dev/stdin

if test $argc -gt 1
    # <INPUT PATH> is specified
    set input_path $argv[-1]
end

echo $input_path

set -l grep_options -i

if set -q _flag_context
    set --append grep_options '-C' $_flag_context
end

set --append grep_options $search_string

begin
    # print head first
    read -l line
    echo "$line"

    # let 'grep' do the rest
    exec grep $grep_options

end < $input_path
