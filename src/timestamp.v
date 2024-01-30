module main

import time

struct TimeStamp {
	time u16 // Number of milliseconds since midnight
	date u16 // One plus number of days since 1/1/0001
}

fn (t TimeStamp) to_time() time.Time {
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

fn from_time(t time.Time) TimeStamp {
	return TimeStamp{
		time: u16(u16(t.hour) << 11 | u16(t.minute) << 5 | t.second >>> 1)
		date: u16(u16((t.year - 1980)) << 9 | u16(t.month) << 5 | t.day)
	}
}

fn (t TimeStamp) str() string {
	return t.to_time().str()
}
