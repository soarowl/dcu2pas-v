module main

import os

pub struct Dcu {
mut:
	path    string
	data    []u8
	pos     usize
	version u32
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

	d.write_file()!
}

fn (d Dcu) write_file() ! {
	mut buffer := '// ${d.version: 08X}'
	os.write_file(d.path + '.pas', buffer)!
}
