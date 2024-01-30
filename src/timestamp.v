module main

import time

pub struct TimeStamp {
	time u16 // Number of milliseconds since midnight
	date u16 // One plus number of days since 1/1/0001
}

pub fn (t TimeStamp) to_time() time.Time {
	year := t.date >> 9 + 1980
	month := t.date >> 5 & 15
	day := t.date & 31
	hour := t.time >> 11
	minute := t.time >> 5 & 63
	second := t.time & 31 << 1
	return time.Time{
		year: year
		month: month
		day: day
		hour: hour
		minute: minute
		second: second
	}
}

pub fn from_time(t time.Time) TimeStamp {
	return TimeStamp{
		time: u16(u16(t.hour) << 11 | u16(t.minute) << 5 | t.second >>> 1)
		date: u16(u16((t.year - 1980)) << 9 | u16(t.month) << 5 | t.day)
	}
}

fn test_time_stamp() {
	ts1 := TimeStamp{
		time: 32570
		date: 22417
	}
	t := ts1.to_time()
	ts2 := from_time(t)
	assert ts1 == ts2
}
