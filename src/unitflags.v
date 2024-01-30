module main

struct UnitFlags {
	flags  u64
	flags1 u64
}

fn (mut d Dcu) decode_unit_flags() !UnitFlags {
	flags := d.get_packed_uint()!
	flags1 := d.get_packed_uint()!
	return UnitFlags{flags, flags1}
}

fn (u UnitFlags) str() string {
	return 'flags: ${u.flags:X}, flags1: ${u.flags1:X}'
}
