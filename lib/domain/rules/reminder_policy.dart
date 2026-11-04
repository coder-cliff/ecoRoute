class ReminderPolicy {
  const ReminderPolicy();

  bool shouldSendReminder({
    required int successfulRequests,
    required bool remindersEnabled,
  }) {
    if (!remindersEnabled) {
      return false;
    }

    return successfulRequests < 5;
  }
}
