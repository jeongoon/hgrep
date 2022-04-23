#!/usr/bin/env python

import os, sys, re
import argparse

# handle options first
parser = argparse.ArgumentParser()#prog="hgrep.py")
parser.add_argument( "-C", "--context",
                     nargs = 1,
                     type = int,
                     dest = "context",
                     required = False,
                     help="print NUM lines of output context" )

parser.add_argument( "search",
                     # upper case in the help message
                     metavar = "<SEARCH>",
                     help = "string to search from <file_path>" )

parser.add_argument( "file_path",
                     # upper case in the help message
                     metavar = "[<FILE PATH>]",
                     default = '-',
                     help = "<file_path> to search" )

# case insenstive search
grep_options = [ '-i' ]

# highligting
if os.environ['TERM'].lower != 'dumb':
    grep_options.append( "--color=auto" )

# argparse cannot handle optional argument
# WORKAROUND:
argv = sys.argv[1::]
if len(argv) == 0:
    print( "{prog}: No argument given".format(prog= sys.argv[0] ),
           file = sys.stderr )
    parser.print_help()
    exit( 1 )

if len(argv) == 1:
    # user ommit input file path
    # default : - (stdin)
    argv.append( '-' )

args = parser.parse_args( argv )

# check more grep options
if args.context is not None and args.context > 0:
    grep_options.extend( [ '-C', args.context ] )

grep_options.append( args.search )

# and let's go for plumbing
# file descriptors r,w for reading and writing
r, w = os.pipe()

if args.file_path == "-":
    # open file path to read
    file_to_read = sys.stdin
else:
    # or from stdin
    if os.path.isfile( args.file_path ):
        file_to_read = open( args.file_path, "r" )
    else:
        print( "A file path:({fp}) is not readable"
               .format( fp=args.file_path )
               , file = sys.stderr )
        exit( 2 )

print( file_to_read.readline() , file = sys.stdout, flush = True )

grep_pid = os.fork()

if grep_pid:
    # parent process

    # to communicate with to a child process
    # writing file descriptor will be used
    os.close(r)
    os.dup2( w, sys.stdout.fileno() )

    # read head first and print into stdout directly

    for line in file_to_read:
        print( line )

    # It is good practice to close all the file open
    os.close( w )

    # safely waiting for children processes
    os.waitpid( grep_pid,
                os.WNOHANG # if child process status not available: no wait
               )

else:
    # child process
    os.dup2( r, sys.stdin.fileno() )
    os.closerange( r, w )
    os.execvp( 'grep', grep_options )

exit(0)
