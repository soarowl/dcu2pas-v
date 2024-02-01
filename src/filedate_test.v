module main

fn test_time_stamp() {
	ts1 := FileDate{
		time: 32570
		date: 22417
	}
	t := ts1.to_time()
	ts2 := from_time(t)
	assert ts1 == ts2
}
