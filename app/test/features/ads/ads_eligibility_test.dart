import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/features/ads/ads_eligibility.dart';

void main() {
  final sessionStart = DateTime(2026, 1, 1, 10, 0);

  group('isInterstitialEligibleAt', () {
    test('bloqueia sem ter aberto o leitor na sessão', () {
      expect(
        isInterstitialEligibleAt(
          now: sessionStart.add(const Duration(minutes: 10)),
          lastShownAt: null,
          sessionStart: sessionStart,
          readerWasOpenedThisSession: false,
          interstitialShownThisSession: const [],
          cooldownMinutes: 15,
          minSessionMinutes: 2,
          maxPerHour: 6,
        ),
        isFalse,
      );
    });

    test('bloqueia antes do tempo mínimo de sessão', () {
      expect(
        isInterstitialEligibleAt(
          now: sessionStart.add(const Duration(minutes: 1)),
          lastShownAt: null,
          sessionStart: sessionStart,
          readerWasOpenedThisSession: true,
          interstitialShownThisSession: const [],
          cooldownMinutes: 15,
          minSessionMinutes: 2,
          maxPerHour: 6,
        ),
        isFalse,
      );
    });

    test('libera após sessão mínima sem interstitial anterior', () {
      expect(
        isInterstitialEligibleAt(
          now: sessionStart.add(const Duration(minutes: 5)),
          lastShownAt: null,
          sessionStart: sessionStart,
          readerWasOpenedThisSession: true,
          interstitialShownThisSession: const [],
          cooldownMinutes: 15,
          minSessionMinutes: 2,
          maxPerHour: 6,
        ),
        isTrue,
      );
    });

    test('respeita cooldown de 15 minutos', () {
      final lastShown = sessionStart.add(const Duration(minutes: 10));

      expect(
        isInterstitialEligibleAt(
          now: sessionStart.add(const Duration(minutes: 20)),
          lastShownAt: lastShown,
          sessionStart: sessionStart,
          readerWasOpenedThisSession: true,
          interstitialShownThisSession: [lastShown],
          cooldownMinutes: 15,
          minSessionMinutes: 2,
          maxPerHour: 6,
        ),
        isFalse,
      );

      expect(
        isInterstitialEligibleAt(
          now: sessionStart.add(const Duration(minutes: 26)),
          lastShownAt: lastShown,
          sessionStart: sessionStart,
          readerWasOpenedThisSession: true,
          interstitialShownThisSession: [lastShown],
          cooldownMinutes: 15,
          minSessionMinutes: 2,
          maxPerHour: 6,
        ),
        isTrue,
      );
    });

    test('respeita teto por hora', () {
      final now = sessionStart.add(const Duration(minutes: 30));
      final recent = List.generate(
        6,
        (index) => now.subtract(Duration(minutes: 50 - index * 5)),
      );

      expect(
        isInterstitialEligibleAt(
          now: now,
          lastShownAt: recent.last,
          sessionStart: sessionStart,
          readerWasOpenedThisSession: true,
          interstitialShownThisSession: recent,
          cooldownMinutes: 15,
          minSessionMinutes: 2,
          maxPerHour: 6,
        ),
        isFalse,
      );
    });
  });

  test('parseLastInterstitialAt converte epoch ms', () {
    final parsed = parseLastInterstitialAt(1_700_000_000_000);
    expect(parsed, DateTime.fromMillisecondsSinceEpoch(1_700_000_000_000));
    expect(parseLastInterstitialAt('invalid'), isNull);
  });
}
