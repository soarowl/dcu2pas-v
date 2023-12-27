module main

fn test_get_id() {
	buffer := [u8(6), 0x55, 0x45, 0x6d, 0x70, 0x74, 0x79]
	mut dcu := Dcu.new('test.dcu', buffer)
	id := dcu.get_id()!
	assert id == 'UEmpty'
}
