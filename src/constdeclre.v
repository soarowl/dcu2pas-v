module main

struct ConstDeclare {
	name string
	u1   u64
	u2   u64
	u3   u64
	u4   u64
	u5   u64
	u6   u64
	u7   u64
}

fn (mut d Dcu) decode_const_declare() !ConstDeclare {
	name := d.get_utf8str()!
	u1 := d.get_packed_uint()!
	u2 := d.get_packed_uint()!
	u3 := d.get_packed_uint()!
	u4 := d.get_packed_uint()!
	u5 := d.get_packed_uint()!
	u6 := d.get_packed_uint()!
	u7 := d.get_packed_uint()!
	return ConstDeclare{name, u1, u2, u3, u4, u5, u6, u7}
}
