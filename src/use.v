module main

struct Use {
mut:
	tag       u8 // 0x64 | 0x65
	name      string
	timestamp TimeStamp
	imports   []UseTypeOrFunc
}

struct UseTypeOrFunc {
	tag       u8 // ox66 | 0x67
	name      string
	timestamp TimeStamp
}

fn (mut d Dcu) decode_uses() ![]Use {
	mut result := []Use{}

	for {
		tag := d.tag
		name := d.get_utf8str()!
		timestamp := d.get[TimeStamp]()!
		mut use := Use{}
		use.tag = tag
		use.name = name
		use.timestamp = timestamp

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
					ts := d.get[TimeStamp]()!
					u := UseTypeOrFunc{t, n, ts}
					use.imports << u

					d.tag = d.get[u8]()!
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
