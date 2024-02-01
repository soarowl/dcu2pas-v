module main

struct SourceFile {
	name          string
	last_modified FileDate
	index         u64
}

fn (mut d Dcu) decode_sourcefiles() ![]SourceFile {
	mut sources := []SourceFile{}
	for {
		name := d.get_utf8str()!
		last_modified := d.get[FileDate]()!
		index := d.get_packed_uint()!
		sources << SourceFile{name, last_modified, index}
		if index == 0 {
			break
		}

		d.tag = d.get[u8]()!
		if d.tag != u8(Tag.source_file) {
			d.pos--
			break
		}
	}

	return sources
}

fn (s SourceFile) str() string {
	return '// ${s.name}, last_modified: ${s.last_modified}, index: ${s.index}'
}

fn (sources []SourceFile) str() string {
	return sources.map(it.str()).join('\n')
}
