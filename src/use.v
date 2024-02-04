module main

struct Use {
mut:
	tag     u8 // 0x64 | 0x65
	name    string
	u1      u64
	u2      u64
	u3      u64
	imports []UseTypeOrFunc
}

struct UseTypeOrFunc {
	tag  u8 // ox66 | 0x67
	name string
	u1   u32
	u2   u32
}

fn (mut d Dcu) decode_uses() ![]Use {
	mut result := []Use{}

	for {
		tag := d.tag
		name := d.get_utf8str()!
		u1 := d.get_packed_uint()!
		u2 := d.get_packed_uint()!
		mut u3 := u64(0)
		if u8(d.compiler) >= u8(Compiler.delphi12) {
			u3 = d.get_packed_uint()!
		}
		mut use := Use{}
		use.tag = tag
		use.name = name
		use.u1 = u1
		use.u2 = u2
		use.u3 = u3

		d.tag = d.get[u8]()!
		match d.tag {
			u8(Tag.stop) {
				again:
				result << use
				// check next tag
				d.tag = d.get[u8]()!
				match d.tag {
					u8(Tag.use_int), u8(Tag.use_imp) {
						continue
					}
					else {
						// back
						d.pos--
						break
					}
				}
			}
			u8(Tag.use_int), u8(Tag.use_imp) {
				continue
			}
			u8(Tag.use_type), u8(Tag.use_func) {
				for {
					t := d.tag
					n := d.get_utf8str()!
					uu1 := d.get[u32]()!
					mut uu2 := u32(0)

					d.tag = d.get[u8]()!
					if d.tag == u8(0x9F) {
						uu2 = d.get[u32]()!
						d.tag = d.get[u8]()!
					}

					u := UseTypeOrFunc{t, n, uu1, uu2}
					use.imports << u

					if d.tag == u8(Tag.stop) {
						break
					}
				}
				unsafe {
					goto again
				}
			}
			else {
				break
			}
		}
	}

	return result
}

fn (u Use) str() string {
	if u.imports.len == 0 {
		return u.name
	} else {
		imported := u.imports.map(it.name).join(', ')
		return '${u.name}{${imported}}'
	}
}

fn (u []Use) int_str() string {
	ints := u.filter(it.tag == u8(Tag.use_int))
	if ints.len == 0 {
		return ''
	} else {
		return 'use\n  ' + ints.map(it.str()).join(', \n  ') + ';\n'
	}
}

fn (u []Use) imp_str() string {
	ints := u.filter(it.tag == u8(Tag.use_imp))
	if ints.len == 0 {
		return ''
	} else {
		return 'use\n  ' + ints.map(it.str()).join(', \n  ') + ';\n'
	}
}
