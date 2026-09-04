/// Regras puras de elegibilidade para interstitial (testáveis sem AdMob SDK).
bool isInterstitialEligibleAt({
  required DateTime now,
  required DateTime? lastShownAt,
  required DateTime sessionStart,
  required bool readerWasOpenedThisSession,
  required List<DateTime> interstitialShownThisSession,
  required int cooldownMinutes,
  required int minSessionMinutes,
  required int maxPerHour,
}) {
  if (!readerWasOpenedThisSession) return false;

  final sessionDuration = now.difference(sessionStart);
  if (sessionDuration < Duration(minutes: minSessionMinutes)) {
    return false;
  }

  if (lastShownAt != null) {
    final sinceLast = now.difference(lastShownAt);
    if (sinceLast < Duration(minutes: cooldownMinutes)) {
      return false;
    }
  }

  final hourAgo = now.subtract(const Duration(hours: 1));
  final shownInLastHour = interstitialShownThisSession
      .where((timestamp) => timestamp.isAfter(hourAgo))
      .length;
  if (shownInLastHour >= maxPerHour) {
    return false;
  }

  return true;
}

DateTime? parseLastInterstitialAt(dynamic raw) {
  if (raw is int) {
    return DateTime.fromMillisecondsSinceEpoch(raw);
  }
  return null;
}
