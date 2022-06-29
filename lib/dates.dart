enum WeekDay { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

extension ToDateTimeWeekDayExtension on WeekDay {
  int toDateTime() {
    switch (index) {
      case 0:
        return DateTime.monday;
      case 1:
        return DateTime.tuesday;
      case 2:
        return DateTime.wednesday;
      case 3:
        return DateTime.thursday;
      case 4:
        return DateTime.friday;
      case 5:
        return DateTime.saturday;
      case 6:
        return DateTime.sunday;
      default:
        throw (RangeError.range(index, 0, 6));
    }
  }

  WeekDay fromDateTime(final DateTime dateTime) {
    switch (dateTime.weekday) {
      case DateTime.monday:
        return WeekDay.monday;
      case DateTime.tuesday:
        return WeekDay.tuesday;
      case DateTime.wednesday:
        return WeekDay.wednesday;
      case DateTime.thursday:
        return WeekDay.thursday;
      case DateTime.friday:
        return WeekDay.friday;
      case DateTime.saturday:
        return WeekDay.saturday;
      case DateTime.sunday:
        return WeekDay.sunday;
      default:
        throw RangeError.range(
            dateTime.weekday, DateTime.monday, DateTime.sunday);
    }
  }
}
