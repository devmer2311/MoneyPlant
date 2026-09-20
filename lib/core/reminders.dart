import 'package:timezone/timezone.dart' as tz;

import 'models.dart';

const reminderImage = 'assets/notifications/garden-reminder.png';

class ReminderPreferences {
  final bool enabled, daily, evening, monthly, weekly, budgetWarnings;
  final int dailyMinute, eveningMinute, monthlyMinute, weeklyMinute, weekday;
  final int budget;
  const ReminderPreferences({
    this.enabled = false,
    this.daily = true,
    this.evening = true,
    this.monthly = true,
    this.weekly = true,
    this.budgetWarnings = true,
    this.dailyMinute = 18 * 60 + 30,
    this.eveningMinute = 21 * 60 + 30,
    this.monthlyMinute = 10 * 60,
    this.weeklyMinute = 18 * 60,
    this.weekday = DateTime.sunday,
    this.budget = 0,
  });
  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'daily': daily,
    'evening': evening,
    'monthly': monthly,
    'weekly': weekly,
    'budgetWarnings': budgetWarnings,
    'dailyMinute': dailyMinute,
    'eveningMinute': eveningMinute,
    'monthlyMinute': monthlyMinute,
    'weeklyMinute': weeklyMinute,
    'weekday': weekday,
    'budget': budget,
  };
  factory ReminderPreferences.fromJson(Map<String, dynamic> j) {
    int minute(String key, int fallback) =>
        j[key] is int && j[key] >= 0 && j[key] < 1440 ? j[key] : fallback;
    return ReminderPreferences(
      enabled: j['enabled'] == true,
      daily: j['daily'] != false,
      evening: j['evening'] != false,
      monthly: j['monthly'] != false,
      weekly: j['weekly'] != false,
      budgetWarnings: j['budgetWarnings'] != false,
      dailyMinute: minute('dailyMinute', 1110),
      eveningMinute: minute('eveningMinute', 1290),
      monthlyMinute: minute('monthlyMinute', 600),
      weeklyMinute: minute('weeklyMinute', 1080),
      weekday: j['weekday'] is int && j['weekday'] >= 1 && j['weekday'] <= 7
          ? j['weekday']
          : 7,
      budget: j['budget'] is int && j['budget'] > 0 ? j['budget'] : 0,
    );
  }
  ReminderPreferences update(String key, Object value) =>
      ReminderPreferences.fromJson({...toJson(), key: value});
}

class ReminderCopy {
  final String title, body, destination;
  const ReminderCopy(this.title, this.body, this.destination);
}

const dailyMessages = [
  ReminderCopy(
    'Kuchu puchu 🌱',
    'Expenses log kiye ya nhi? Chalo, aaj ke chhote spends ko ghar de dein 💚',
    'expense',
  ),
  ReminderCopy(
    'Chai, coffee aur tum ☕',
    'Aaj ka spend yaad hai? Ek tiny entry, phir full chill ✨',
    'expense',
  ),
  ReminderCopy(
    'Your plant says hii 🪴',
    'Thoda pyaar, thoda hisaab. Aaj ke expenses add kar dein? 💖',
    'expense',
  ),
  ReminderCopy(
    'Little money date? 💌',
    'Bas ek minute apne liye. Aaj kahan kharch hua, note kar lo 🌼',
    'expense',
  ),
  ReminderCopy(
    'Puchu, tiny check-in 🐣',
    'Snacks se shopping tak, aaj ke spends ko log kar lo 🛍️',
    'expense',
  ),
  ReminderCopy(
    'Weekend wali care 🌈',
    'Masti bhi, money care bhi. Aaj ka expense add kiya? ✨',
    'expense',
  ),
  ReminderCopy(
    'Soft Sunday nudge ☁️',
    'Apne money plant ko ek little update de do. Expenses log kar lein? 🌱',
    'expense',
  ),
];
const eveningMessages = [
  ReminderCopy(
    'Din khatm hone ko aaya 🌙',
    'Are puchu, kab karoge aaj ka spend add? Chalo, phir aaram 💖',
    'expense',
  ),
  ReminderCopy(
    'Goodnight, money plant 💤',
    'Sone se pehle aaj ka hisaab? Ek chhoti entry aur sweet dreams ✨',
    'expense',
  ),
  ReminderCopy(
    'Moonlight money check 🌛',
    'Aaj ke expenses abhi baaki hain. Do minute, phir cozy time 🧸',
    'expense',
  ),
  ReminderCopy(
    'Psst… kuch bhoola? 🐥',
    'Din toh nikal gaya, spends bhi note kar lo. Kal ke tum ko thank you 💚',
    'expense',
  ),
  ReminderCopy(
    'Wrap it up, cutie 🎀',
    'Aaj ka last little task: expenses log kar lo. You got this 🌱',
    'expense',
  ),
  ReminderCopy(
    'Cozy night check-in 🧸',
    'Aaj ki outing ka spend add hua? Bas ek tiny money moment 🌙',
    'expense',
  ),
  ReminderCopy(
    'New week, light mind ✨',
    'Aaj ke spends note kar do. Kal ek fresh little start 🌼',
    'expense',
  ),
];
const monthlyMessage = ReminderCopy(
  'Naya month, fresh leaves 🌱',
  'Are plant watering kab karoge? Month start ho gaya! Budget set karo, savings ko thoda pyaar do 💧💖',
  'home',
);
const weeklyMessage = ReminderCopy(
  'Split ka scene clear karein? 🫶',
  'Puchu, weekly hisaab time! Jo splits pending hain, unhe pyaar se settle kar lo 💸✨',
  'splits',
);
ReminderCopy budgetMessage(int threshold) => threshold == 100
    ? const ReminderCopy(
        'Budget needs a little hug 🧸',
        'Is month ka budget reach ho gaya. Koi guilt nahi — spends check karke next step plan karein? 🌱',
        'insights',
      )
    : const ReminderCopy(
        'Tiny budget heads-up 🍃',
        'Budget ka 80% use ho gaya, puchu. Ek chhota pause aur spending check? You’ve got this 💚',
        'insights',
      );

enum ReminderRepeat { weekly, monthly }

class PlannedReminder {
  final int id;
  final ReminderCopy copy;
  final tz.TZDateTime date;
  final ReminderRepeat repeat;
  const PlannedReminder(this.id, this.copy, this.date, this.repeat);
}

const scheduledReminderIds = [
  1101,
  1102,
  1103,
  1104,
  1105,
  1106,
  1107,
  1201,
  1202,
  1203,
  1204,
  1205,
  1206,
  1207,
  1300,
  1400,
];

List<PlannedReminder> planReminders(
  ReminderPreferences p,
  tz.TZDateTime now, {
  required bool hasSplits,
}) {
  if (!p.enabled) return [];
  final result = <PlannedReminder>[];
  tz.TZDateTime weekly(int day, int minute) {
    final offset = (day - now.weekday + 7) % 7;
    var date = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + offset,
      minute ~/ 60,
      minute % 60,
    );
    if (!date.isAfter(now)) {
      date = tz.TZDateTime(
        now.location,
        now.year,
        now.month,
        now.day + offset + 7,
        minute ~/ 60,
        minute % 60,
      );
    }
    return date;
  }

  for (var day = 1; day <= 7; day++) {
    if (p.daily) {
      result.add(
        PlannedReminder(
          1100 + day,
          dailyMessages[day - 1],
          weekly(day, p.dailyMinute),
          ReminderRepeat.weekly,
        ),
      );
    }
    if (p.evening) {
      result.add(
        PlannedReminder(
          1200 + day,
          eveningMessages[day - 1],
          weekly(day, p.eveningMinute),
          ReminderRepeat.weekly,
        ),
      );
    }
  }
  if (p.monthly) {
    var date = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      1,
      p.monthlyMinute ~/ 60,
      p.monthlyMinute % 60,
    );
    if (!date.isAfter(now)) {
      date = tz.TZDateTime(
        now.location,
        now.year,
        now.month + 1,
        1,
        p.monthlyMinute ~/ 60,
        p.monthlyMinute % 60,
      );
    }
    result.add(
      PlannedReminder(1300, monthlyMessage, date, ReminderRepeat.monthly),
    );
  }
  if (p.weekly && hasSplits) {
    result.add(
      PlannedReminder(
        1400,
        weeklyMessage,
        weekly(p.weekday, p.weeklyMinute),
        ReminderRepeat.weekly,
      ),
    );
  }
  return result;
}

int monthlySpending(Iterable<Entry> entries, DateTime now) => entries
    .where(
      (e) =>
          !e.incoming &&
          !e.date.isAfter(now) &&
          e.date.year == now.year &&
          e.date.month == now.month,
    )
    .fold(0, (total, e) => total + e.amount);

int nextBudgetWarning(int spent, int budget, int lastThreshold) {
  if (budget <= 0) return 0;
  if (spent >= budget && lastThreshold < 100) return 100;
  if (spent * 100 >= budget * 80 && lastThreshold < 80) return 80;
  return 0;
}
