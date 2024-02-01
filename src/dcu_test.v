module main

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
	data := [u8(0b101_1111), 2, 3, 4, 0b1000_0000]
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
	data := [u8(8), 0b101, 3, 0b1011, 5, 6, 0b10111, 8, 9, 0, 0b101_1111, 2, 3, 4, 8, 0xff, 1,
		2, 3, 4, 5, 6, 7, 8, 0b1111_1111, 1, 2, 3, 4, 5, 6, 7, 8]
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

fn test_get_packed_uint() ! {
	data := [u8(8), 0b101, 3, 0b1011, 5, 6, 0b10111, 8, 9, 0, 0b101_1111, 2, 3, 4, 8, 0xff, 1,
		2, 3, 4, 5, 6, 7, 8]
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
