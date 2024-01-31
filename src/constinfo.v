module main

struct ConstInfo {
	name string
	u1   u64
	u2   u64
	u3   u64
	u4   u64
}

fn (mut d Dcu) decode_const_info() !ConstInfo {
	name := d.get_utf8str()!
	u1 := d.get_packed_uint()!
	u2 := d.get_packed_uint()!
	u3 := d.get_packed_uint()!
	u4 := d.get_packed_uint()!
	d.tag = d.get[u8]()!
	assert d.tag == 0x63
	return ConstInfo{name, u1, u2, u3, u4}
}
