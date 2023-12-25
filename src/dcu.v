module main

import os

enum Compiler as u8 {
	delphi6    = 0x0E
	delphi7    = 0x0F
	delphi2005 = 0x11
	delphi2006 = 0x12
	delphi2009 = 0x14
	delphi2010 = 0x15
	delphixe   = 0x16
	delphixe2  = 0x17
	delphixe3  = 0x18
	delphixe4  = 0x19
	delphixe5  = 0x1A
	delphixe6  = 0x1B
	delphixe7  = 0x1C
	delphixe8  = 0x1D
	delphi10   = 0x1E
	delphi10_1 = 0x1F
	delphi10_2 = 0x20
	delphi10_3 = 0x21
	delphi10_4 = 0x22
	delphi11   = 0x23
	delphi12   = 0x24
}

pub struct Dcu {
mut:
	path string
	data []u8
	pos  usize

	version  u32
	compiler Compiler
	platform u8

	size u32
	date u32
	crc  u32
}

pub fn (mut d Dcu) decompile(path string) ! {
	d.path = path
	d.data = os.read_bytes(path)!
	d.decode()!
}

fn (mut d Dcu) decode() ! {
	unsafe {
		d.compiler = Compiler(d.data[3])
	}
	d.platform = d.data[1]
	d.version = d.get[u32]()!
	d.size = d.get[u32]()!
	d.date = d.get[u32]()!
	d.crc = d.get[u32]()!

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
	version_map := {
		Compiler.delphi6: 'Borland Delphi 6'
		.delphi7:         'Borland Delphi 7'
		.delphi2005:      'Borland Delphi 2005'
		.delphi2006:      'Borland Delphi 2006'
		.delphi2009:      'Codegear Delphi 2009'
		.delphi2010:      'Codegear Delphi 2010'
		.delphixe:        'Embarcadero Delphi XE'
		.delphixe2:       'Embarcadero Delphi XE2'
		.delphixe3:       'Embarcadero Delphi XE3'
		.delphixe4:       'Embarcadero Delphi XE4'
		.delphixe5:       'Embarcadero Delphi XE5'
		.delphixe6:       'Embarcadero Delphi XE6'
		.delphixe7:       'Embarcadero Delphi XE7'
		.delphixe8:       'Embarcadero Delphi XE8'
		.delphi10:        'Embarcadero Delphi 10 Seattle'
		.delphi10_1:      'Embarcadero Delphi 10.1 Berlin'
		.delphi10_2:      'Embarcadero Delphi 10.2 Tokyo'
		.delphi10_3:      'Embarcadero Delphi 10.3 Rio'
		.delphi11:        'Embarcadero Delphi 11 Alexandria'
		.delphi12:        'Embarcadero Delphi 12 Athens'
	}
	mut buffer := '// version: ${d.version:08X}
// compiler: ${version_map[d.compiler]}
// platform: ${d.platform}
// size: ${d.size}
// compile date: ${d.date}
// crc: ${d.crc}
'
	os.write_file(d.path + '.pas', buffer)!
}
