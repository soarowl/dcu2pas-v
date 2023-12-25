module main

import os

pub struct Dcu {
mut:
	path string
	data []u8
}

pub fn (mut d Dcu) decompile(path string) ! {
	d.path = path
	d.data = os.read_bytes(path)!
	d.decode()
}

pub fn (mut d Dcu) decode() {
}
