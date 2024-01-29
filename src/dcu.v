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

struct Dcu {
	path string
	data []u8
mut:
	name string
	pos  usize

	magic    u32
	compiler Compiler
	platform Platform

	size          u32
	compiled_time TimeStamp
	crc           u32

	tag u8
}

fn Dcu.new(path string, data []u8) Dcu {
	return Dcu{
		path: path
		data: data
	}
}

fn (mut d Dcu) decode() ! {
	unsafe {
		d.compiler = Compiler(d.data[3])
		d.platform = Platform(d.data[1])
	}
	d.magic = d.get[u32]()!
	d.size = d.get[u32]()!
	d.compiled_time = d.get[TimeStamp]()!
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

fn (mut d Dcu) get_utf8str() !string {
	errmsg := 'End of file'
	if d.pos <= d.data.len {
		len := d.data[d.pos]
		d.pos++
		if d.pos + len <= d.data.len {
			v := d.data[d.pos..d.pos + len]
			d.pos += len
			return v.bytestr()
		} else {
			return error(errmsg)
		}
	}
	return error(errmsg)
}

fn (d Dcu) int_str() string {
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
	plateform_map := {
		Platform.win32_0: 'Win32'
		.win64:           'Win64'
		.osx32:           'OSX32'
		.iossimulator:    'iOSSimulator'
		.android32_67:    'Android32'
		.iosdevice32:     'iOSDevice32'
		.android32:       'Android32'
		.android64:       'Android64'
		.iosdevice64:     'iOSDevice64'
	}

	compiled_time := d.compiled_time.to_time()
	buffer := '// magic: ${d.magic:08X}
// compiler: ${version_map[d.compiler]}
// platform: ${plateform_map[d.platform]}
// size: ${d.size}
// compile time: ${compiled_time}
// crc: ${d.crc}

unit ${d.name};

interface

'
	return buffer
}

fn (d Dcu) imp_str() string {
	return ''
}

fn (d Dcu) str() string {
	return '${d.int_str()}

implementation

${d.imp_str()}

end.
'
}

enum Platform as u8 {
	win32_0      = 0x00
	win32        = 0x03
	win64        = 0x23
	osx32        = 0x04
	iossimulator = 0x14
	android32_67 = 0x67
	iosdevice32  = 0x76
	android32    = 0x77
	android64    = 0x87
	iosdevice64  = 0x94
}

fn (d Dcu) write_file() ! {
	os.write_file(d.path + '.pas', d.str())!
}
