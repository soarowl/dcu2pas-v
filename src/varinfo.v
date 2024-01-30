module main

struct VarInfo {
	name         string
	type_index   u64
	offset       u64
	package_flag u64
}

fn (mut d Dcu) decode_var_info() !VarInfo {
	name := d.get_utf8str()!
	type_index := d.get_packed_uint()!
	offset := d.get_packed_uint()!
	package_flag := d.get_packed_uint()!
	return VarInfo{name, type_index, offset, package_flag}
}
