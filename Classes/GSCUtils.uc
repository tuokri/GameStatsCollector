class GSCUtils extends Object
    notplaceable;

var private int Year;
var private int Month;
var private int DayOfWeek;
var private int Day;
var private int Hour;
var private int Min;
var private int Sec;
var private int MSec;

// Warning: only takes MSec, Sec, Min and Hour into account.
final function float GetSystemTimeStamp()
{
    GetSystemTime(Year, Month, DayOfWeek, Day, Hour, Min, Sec, MSec);
    return (Hour * 3600) + (Min * 60) + Sec + (MSec / 1000);
}
