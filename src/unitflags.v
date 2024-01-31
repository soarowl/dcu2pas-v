module main

struct UnitFlags {
	flags1 u64
	flags2 u64
	flags3 u64
}

fn (mut d Dcu) decode_unit_flags() !UnitFlags {
	flags1 := d.get_packed_uint()!
	flags2 := d.get_packed_uint()!
	if u8(d.compiler) >= u8(Compiler.delphi12) {
		flags3 := d.get_packed_uint()!
		return UnitFlags{flags1, flags2, flags3}
	}

	return UnitFlags{flags1, 0, flags2}
}

fn (u UnitFlags) str() string {
	return 'Unit flags: flags1: ${u.flags1:X}, flags2: ${u.flags2:X} flags3: ${u.flags3:X}'
}
