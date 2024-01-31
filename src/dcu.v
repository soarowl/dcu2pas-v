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
	pos  usize // Current position in data when decode processing

	magic    u32
	compiler Compiler
	platform Platform

	size          u32
	compiled_time TimeStamp
	crc           u32

	tag u8

	unit_addtional_info UnitAddtionalInfo
	unit_flags          UnitFlags
	sourcefiles         []SourceFile
	uses                []Use
	declares            []Declare
}

const err_msg_end_of_file = 'Unexpected end of file'
const err_msg_invlid_format = 'Invalid format'

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

	for {
		d.tag = d.get[u8]()!
		match d.tag {
			u8(Tag.source_file) {
				d.sourcefiles = d.decode_sourcefiles()!
			}
			u8(Tag.start) {
				continue
			}
			u8(Tag.unit_addtional_info) {
				d.unit_addtional_info = d.decode_unit_addtional_info()!
			}
			u8(Tag.unit_flags) {
				d.unit_flags = d.decode_unit_flags()!
			}
			u8(Tag.use_int) {
				d.uses = d.decode_uses()!
			}
			u8(Tag.var_info) {
				v := d.decode_var_info()!
				d.declares << v
			}
			else {
				println('Unknown tag: ${d.tag:02X} at ${(d.pos - 1):X}!!!')
				break
			}
		}
	}

	d.write_file()!
}

fn (d Dcu) get[T]() !T {
	if d.pos + sizeof(T) <= d.data.len {
		unsafe {
			v := *(&T(&d.data[d.pos]))
			d.pos += sizeof(T)
			return v
		}
	} else {
		return error(err_msg_end_of_file)
	}
}

fn (mut d Dcu) get_packed_int() !i64 {
	val8 := d.get[i8]()!
	if val8 & 0b1 == 0 {
		return val8 >> 1
	}

	if val8 & 0b11 == 0b01 {
		d.pos--
		val16 := d.get[i16]()!
		return val16 >> 2
	}

	// Usually it will not out of boundary!!!
	if val8 & 0b111 == 0b011 {
		d.pos--
		mut val32 := d.get[i32]()!
		d.pos--
		val32 &= 0x00FFFFFF
		// check sign and set sign
		if val32 & 0x800000 != 0 {
			val32 |= 0xFF_000000
		}
		return val32 >> 3
	}

	if val8 & 0b1111 == 0b0111 {
		d.pos--
		val32 := d.get[i32]()!
		return val32 >> 4
	}

	if val8 == 0b1111 {
		val32 := d.get[i32]()!
		return val32
	}

	if val8 == -1 {
		val64 := d.get[i64]()!
		return val64
	}

	return error(err_msg_invlid_format)
}

fn (mut d Dcu) get_packed_uint() !u64 {
	val8 := d.get[u8]()!
	if val8 & 0b1 == 0 {
		return val8 >>> 1
	}

	if val8 & 0b11 == 0b01 {
		d.pos--
		val16 := d.get[u16]()!
		return val16 >>> 2
	}

	// Usually it will not out of boundary!!!
	if val8 & 0b111 == 0b011 {
		d.pos--
		val32 := d.get[u32]()!
		d.pos--
		return val32 & 0x00FFFFFF >>> 3
	}

	if val8 & 0b1111 == 0b0111 {
		d.pos--
		val32 := d.get[u32]()!
		return val32 >>> 4
	}

	if val8 == 0b1111 {
		val32 := d.get[u32]()!
		return val32
	}

	if val8 == 0xFF {
		val64 := d.get[u64]()!
		return val64
	}

	return error(err_msg_invlid_format)
}

fn (mut d Dcu) get_utf8str() !string {
	if d.pos < d.data.len {
		len := d.data[d.pos]
		d.pos++
		if d.pos + len <= d.data.len {
			v := d.data[d.pos..d.pos + len]
			d.pos += len
			return v.bytestr()
		} else {
			return error(err_msg_end_of_file)
		}
	}
	return error(err_msg_end_of_file)
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
		.delphi10_4:      'Embarcadero Delphi 10.4 Sydney'
		.delphi11:        'Embarcadero Delphi 11 Alexandria'
		.delphi12:        'Embarcadero Delphi 12 Athens'
	}
	plateform_map := {
		Platform.win32_0: 'Win32'
		.win32:           'Win32'
		.win64:           'Win64'
		.osx32:           'OSX32'
		.iossimulator:    'iOSSimulator'
		.android32_67:    'Android32'
		.iosdevice32:     'iOSDevice32'
		.android32:       'Android32'
		.android64:       'Android64'
		.iosdevice64:     'iOSDevice64'
	}

	buffer := '// magic: ${d.magic:08X}
// compiler: ${version_map[d.compiler]}
// platform: ${plateform_map[d.platform]}
// size: ${d.size}
// compile time: ${d.compiled_time}
// crc: ${d.crc}
// ${d.unit_addtional_info}
// ${d.unit_flags}
${d.sourcefiles}

unit ${d.name};

interface

${d.uses.int_str()}
'
	return buffer
}

fn (d Dcu) imp_str() string {
	return '${d.uses.imp_str()}'
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

enum Tag as u8 {
	start               = 0
	unit_addtional_info = 0x02 // ? Delphi12
	var_info            = 0x20
	stop                = 0x63
	use_int             = 0x64 // interface
	use_imp             = 0x65 // implementation
	use_type            = 0x66
	use_func            = 0x67
	source_file         = 0x70
	unit_flags          = 0x96
}

type Declare = VarInfo
