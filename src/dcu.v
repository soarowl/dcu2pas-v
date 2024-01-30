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

fn test_get_signed() ! {
	data := [u8(1), 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 8, 9]
	mut dcu := Dcu.new('test.dcu', data)
	i_1 := dcu.get[i8]()!
	assert 1 == i_1
	i_2 := dcu.get[i16]()!
	assert 0x0302 == i_2
	i_4 := dcu.get[i32]()!
	assert 0x07060504 == i_4
	i_8 := dcu.get[i64]()!
	assert 0x08040302_01000908 == i_8
}

fn test_get_unsigned() ! {
	data := [u8(1), 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 8, 9]
	mut dcu := Dcu.new('test.dcu', data)
	i_1 := dcu.get[u8]()!
	assert 1 == i_1
	i_2 := dcu.get[u16]()!
	assert 0x0302 == i_2
	i_4 := dcu.get[u32]()!
	assert 0x07060504 == i_4
	i_8 := dcu.get[u64]()!
	assert 0x08040302_01000908 == i_8
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

fn test_get_packed_int_minus_i7() ! {
	data := [u8(0b1000_0010)]
	mut dcu := Dcu.new('test.dcu', data)
	i_1 := dcu.get_packed_int()!
	assert 0b111110 + 1 == -i_1
}

fn test_get_packed_int_minus_i14() ! {
	data := [u8(0b1000_0101), 0b1000_0011]
	mut dcu := Dcu.new('test.dcu', data)
	i_2 := dcu.get_packed_int()!
	assert 0b1111100011110 + 1 == -i_2
}

fn test_get_packed_int_minus_i21() ! {
	data := [u8(0b1011), 5, 0b1000_0000, 0]
	mut dcu := Dcu.new('test.dcu', data)
	i_3 := dcu.get_packed_int()!
	assert 0b11111111111101011110 + 1 == -i_3
}

fn test_get_packed_int_minus_i28() ! {
	data := [u8(0b10111), 8, 9, 0b1000_0000]
	mut dcu := Dcu.new('test.dcu', data)
	i_4 := dcu.get_packed_int()!
	assert 0b111111111110110111101111110 + 1 == -i_4
}

fn test_get_packed_int_minus_i32() ! {
	data := [u8(0b1111), 2, 3, 4, 0b1000_0000]
	mut dcu := Dcu.new('test.dcu', data)
	i_5 := dcu.get_packed_int()!
	assert 0b1111111111110111111110011111110 == -i_5
}

fn test_get_packed_int_minus_i64() ! {
	data := [u8(0xff), 1, 2, 3, 4, 5, 6, 7, 0b1000_0000]
	mut dcu := Dcu.new('test.dcu', data)
	i_6 := dcu.get_packed_int()!
	assert 0b111111111111000111110011111101011111011111111001111110111111111 == -i_6
}

fn test_get_packed_int_plus() ! {
	data := [u8(8), 0b101, 3, 0b1011, 5, 6, 0b10111, 8, 9, 0, 0b1111, 2, 3, 4, 8, 0xff, 1, 2, 3,
		4, 5, 6, 7, 8, 0b1111_1111, 1, 2, 3, 4, 5, 6, 7, 8]
	mut dcu := Dcu.new('test.dcu', data)
	i_1 := dcu.get_packed_int()!
	assert 0b100 == i_1
	i_2 := dcu.get_packed_int()!
	assert 0b0011_0000_01 == i_2
	i_3 := dcu.get_packed_int()!
	assert 0b110_00000101_0000_1 == i_3
	i_4 := dcu.get_packed_int()!
	assert 0b1001_00001000_0001 == i_4
	i_5 := dcu.get_packed_int()!
	assert 0x08040302 == i_5
	i_6 := dcu.get_packed_int()!
	assert 0x0807060504030201 == i_6
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

fn test_get_packed_uint() ! {
	data := [u8(8), 0b101, 3, 0b1011, 5, 6, 0b10111, 8, 9, 0, 0b1111, 2, 3, 4, 8, 0xff, 1, 2, 3,
		4, 5, 6, 7, 8]
	mut dcu := Dcu.new('test.dcu', data)
	i_1 := dcu.get_packed_uint()!
	assert 0b100 == i_1
	i_2 := dcu.get_packed_uint()!
	assert 0b0011_0000_01 == i_2
	i_3 := dcu.get_packed_uint()!
	assert 0b110_00000101_0000_1 == i_3
	i_4 := dcu.get_packed_uint()!
	assert 0b1001_00001000_0001 == i_4
	i_5 := dcu.get_packed_uint()!
	assert 0x08040302 == i_5
	i_6 := dcu.get_packed_uint()!
	assert 0x0807060504030201 == i_6
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

fn test_get_utf8str() ! {
	data := [u8(6), 0x55, 0x45, 0x6d, 0x70, 0x74, 0x79]
	mut dcu := Dcu.new('test.dcu', data)
	id := dcu.get_utf8str()!
	assert id == 'UEmpty'
}

fn test_get_utf8str_chinese() ! {
	data := [u8(15), 0xe4, 0xb8, 0xad, 0xe6, 0x96, 0x87, 0xe5, 0xad, 0x97, 0xe7, 0xac, 0xa6, 0xe4,
		0xb8, 0xb2]
	mut dcu := Dcu.new('test.dcu', data)
	id := dcu.get_utf8str()!
	assert id == '中文字符串'
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
