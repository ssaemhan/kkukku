import Foundation
var cal = Calendar(identifier: .gregorian)
cal.timeZone = TimeZone(identifier: "Asia/Seoul")!
func date(_ d:Int,_ h:Int=0,_ m:Int=0)->Date { cal.date(from: DateComponents(year:2026,month:11,day:d,hour:h,minute:m))! }
func earned(_ d:Int,_ h:Int,_ start:Int=540,_ end:Int=1080,_ days:Set<Int>=[2,3,4,5,6])->Int {
 earnedSalary(monthly:3_000_000,now:date(d,h),weekdays:days,startMinute:start,endMinute:end,calendar:cal)
}
assert(earned(2,8)==0)
assert(earned(2,9)==0)
assert(earned(2,12)>0)
assert(earned(2,18)==earned(3,8))
assert(earned(21,12)==earned(23,9))
assert(earned(30,18)==3_000_000)
assert(earned(16,0,0,1440,Set(1...7))==1_500_000)
assert(earned(7,2,1320,360,[6])>earned(7,0,1320,360,[6]))
assert(earned(7,6,1320,360,[6])==earned(7,20,1320,360,[6]))
assert(earned(1,3,1320,360,[7])>0) // Previous month's overnight shift.
assert(parseWorkTime("09:30")==570)
assert(parseWorkTime("24:00")==nil)
assert(parseWorkTime("24:00",allowEndOfDay:true)==1440)
assert(parseWorkTime("09:60")==nil)
assert(parseWorkTime("abc")==nil)
print("PASS: working hours, off-hours, weekends, full month, 24h compatibility, overnight/month boundary, time validation")
