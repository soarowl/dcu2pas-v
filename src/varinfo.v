module main

struct VarInfo {
	name         string
	type_index   u64
	u1           u64
	u2           u64
	offset       u64
	package_flag u64
}

fn (mut d Dcu) decode_var_info() !VarInfo {
	name := d.get_utf8str()!
	type_index := d.get_packed_uint()!
	mut u1 := u64(0)
	mut u2 := u64(0)
	if u8(d.compiler) >= u8(Compiler.delphi12) {
		u1 = d.get_packed_uint()!
		u2 = d.get_packed_uint()!
	}
	offset := d.get_packed_uint()!
	package_flag := d.get_packed_uint()!
	return VarInfo{name, type_index, u1, u2, offset, package_flag}
}
