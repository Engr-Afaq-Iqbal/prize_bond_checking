import 'package:intl/intl.dart';

class AppFormatDate {
  static String ddMMM12h(DateTime? dateTime) {
    if (dateTime == null) return '- -';
    return DateFormat('dd MMM, hh:mm a').format(dateTime);
  }

  static String yyyyMMDD12h(DateTime? dateTime) {
    if (dateTime == null) return '- -';
    return DateFormat('yyyy-MM-dd, hh:mm:ss a').format(dateTime);
  }

  static String ddMMYYYY(DateTime? dateTime) {
    if (dateTime == null) return '- -';
    return DateFormat('MM/dd/yyyy').format(dateTime);
  }

  static String ddMMMMYYYY(DateTime? dateTime) {
    if (dateTime == null) return '- -';
    return DateFormat('d MMMM, yyyy').format(dateTime);
  }

  static String ddMMYYYYWithDot(DateTime? dateTime) {
    if (dateTime == null) return '- -';
    return DateFormat('dd.MM.yyyy').format(dateTime);
  }

  static String yyyyMMDDWithDash(DateTime? dateTime) {
    if (dateTime == null) return '- -';
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  static String hhMMA(DateTime? dateTime) {
    if (dateTime == null) return '- -';
    return DateFormat('hh:mm a').format(dateTime);
  }

  static String hhmmDifference(DateTime? dateTime) {
    if (dateTime == null) return '- -';
    return "${DateTime.now().difference(dateTime).inHours}:${DateTime.now().difference(dateTime).inMinutes.remainder(60)}";
  }

  static String? doubleToStringUpTo2(String? number) {
    if (number == null) return null;
    return double.tryParse(number)?.toStringAsFixed(2);
  }

  static String formatHijriDate(String hijriDate) {
    // Split the date by the dash (-)
    List<String> parts = hijriDate.split('-');

    // Ensure that we have three parts (year, month, day)
    if (parts.length == 3) {
      // Pad the month and day with leading zeros if necessary
      String year = parts[2];
      String month = parts[1].padLeft(2, '0');
      String day = parts[0].padLeft(2, '0');

      return '$year-$month-$day';
    }

    // Return the original date if it doesn't match the expected format
    return hijriDate;
  }

  String extractDateFromDateTimeString(String dateTimeString) {
    try {
      // Parse the string to DateTime
      DateTime dateTime = DateTime.parse(dateTimeString);

      // Format the DateTime to only show the date
      String formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);

      return formattedDate;
    } catch (e) {
      // Handle any errors, such as invalid date formats
      return '--:--:--';
    }
  }

  static List<String> hijriMonthNames = [
    "Muharram",
    "Safar",
    "Rabi' al-Awwal",
    "Rabi' al-Thani",
    "Jumada al-Awwal",
    "Jumada al-Thani",
    "Rajab",
    "Sha'ban",
    "Ramadan",
    "Shawwal",
    "Dhul-Qa'dah",
    "Dhul-Hijjah",
  ];

  static String gregorianMonthName(int month) {
    List<String> months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return (month >= 1 && month <= 12) ? months[month - 1] : "Invalid Month";
  }

  static String hijriMonthName(int monthIndex) {
    if (monthIndex < 1 || monthIndex > 12) {
      throw ArgumentError("Hijri month index must be between 1 and 12");
    }
    return hijriMonthNames[monthIndex - 1];
  }
}
