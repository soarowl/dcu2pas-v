module main

import os
import prantlf.cli { Cli, run }

const version = '0.0.1'

const usage = 'Decompile dcu(Delphi Compiled Unit) to pas.

Usage: dcu2pas [options] [<dcu-file>]

<dcu-file>                  Decompiled unit file.

Options:
  -V|--version              print the version of the executable and exits
  -h|--help                 print the usage information and exits

Examples:
  $ dcu2pas demo.dcu test.dcu
  $ dcu2pas -V'

struct Opts {
}

fn main() {
	run(Cli{
		usage: usage
		version: version
	}, body)
}

fn body(opts &Opts, args []string) ! {
	if args.len > 0 {
		for arg in args {
			data := os.read_bytes(arg)!
			mut dcu := Dcu.new(arg, data)
			println('Decompile ${arg}...')
			dcu.decode()!
		}
		println('Done.')
	}
}
