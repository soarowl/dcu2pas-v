module main

struct ConstInfo {
	name   string
	u1     u64
	buffer []u8
}

fn (mut d Dcu) decode_const_info() !ConstInfo {
	name := d.get_utf8str()!
	u1 := d.get_packed_uint()!
	d.pos--
	buffer := if u1 >= 0x40 { d.get_bytes(8)! } else { d.get_bytes(4)! }
	for {
		d.tag = d.get[u8]()!
		if d.tag != 0x63 {
			// back
			d.pos--
			break
		}
	}
	return ConstInfo{name, u1, buffer}
}
