module main

struct UnitAddtionalInfo {
	name string
	u1   u64
	u2   u64
}

fn (mut d Dcu) decode_unit_addtional_info() !UnitAddtionalInfo {
	name := d.get_utf8str()!
	u1 := d.get_packed_uint()!
	u2 := d.get_packed_uint()!
	d.name = name
	return UnitAddtionalInfo{name, u1, u2}
}

fn (u UnitAddtionalInfo) str() string {
	return 'Unit addtional info: name: ${u.name}, u1: ${u.u1:X}, u2: ${u.u2:X}'
}
