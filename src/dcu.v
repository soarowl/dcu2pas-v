module main

import os

pub struct Dcu {
mut:
	path    string
	data    []u8
	pos     usize

	version u32
	compiler_version u8
	platform u8

	size usize
}

pub fn (mut d Dcu) decompile(path string) ! {
	d.path = path
	d.data = os.read_bytes(path)!
	d.decode()!
}

fn (mut d Dcu) decode() ! {
	unsafe {
		d.version = *(&u32(&d.data[d.pos]))
	}
	d.compiler_version = d.data[3]
	d.platform = d.data[1]
	d.pos += 4

	d.write_file()!
}

fn (d Dcu) write_file() ! {
	mut buffer := '// version: ${d.version: 08X}'
	os.write_file(d.path + '.pas', buffer)!
}
