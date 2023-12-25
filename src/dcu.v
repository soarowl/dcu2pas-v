module main

import os

pub struct Dcu {
mut:
	path string
	data []u8
	pos  usize

	version          u32
	compiler_version u8
	platform         u8

	size usize
}

pub fn (mut d Dcu) decompile(path string) ! {
	d.path = path
	d.data = os.read_bytes(path)!
	d.decode()!
}

fn (mut d Dcu) decode() ! {
	d.compiler_version = d.data[3]
	d.platform = d.data[1]
	d.version = d.get[u32]()!

	d.write_file()!
}

fn (d Dcu) get[T]() !T {
	if d.pos + sizeof(T) < d.data.len {
		unsafe {
			v := *(&T(&d.data[d.pos]))
			d.pos += sizeof(T)
			return v
		}
	} else {
		return error('End of file')
	}
}

fn (d Dcu) write_file() ! {
	mut buffer := '// version: ${d.version:08X}\n// compiler: ${d.compiler_version}\n// platform: ${d.platform}\n'
	os.write_file(d.path + '.pas', buffer)!
}
