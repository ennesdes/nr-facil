import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:nrfacil/core/constants/app_config.dart';
import 'package:nrfacil/core/services/storage_service.dart';
import 'package:nrfacil/core/utils/app_logger.dart';
import 'package:nrfacil/features/ads/ads_eligibility.dart';

/// Centraliza banners, interstitials e flag futura de IAP (remove ads).
class AdsService extends GetxService {
  static const _keyLastInterstitialAtMs = 'ads_last_interstitial_at_ms';
  static const _keyAdsRemoved = 'ads_removed';

  AdsService({required this.storage});

  final StorageService storage;

  final DateTime _sessionStart = DateTime.now();

  final adsRemoved = false.obs;

  InterstitialAd? _interstitialAd;
  var _isLoadingInterstitial = false;
  var _isShowingInterstitial = false;
  var _readerWasOpenedThisSession = false;
  final List<DateTime> _interstitialShownThisSession = [];

  @override
  void onInit() {
    super.onInit();
    adsRemoved.value = storage.read(_keyAdsRemoved) == true;
    if (shouldShowAds) {
      _preloadInterstitial();
    }
  }

  @override
  void onClose() {
    _interstitialAd?.dispose();
    super.onClose();
  }

  bool get shouldShowAds =>
      AppConfig.adsEnabled && !kIsWeb && !adsRemoved.value;

  void onReaderOpened() {
    _readerWasOpenedThisSession = true;
    if (shouldShowAds) {
      _preloadInterstitial();
    }
  }

  Future<void> onReaderClosed() async {
    if (!shouldShowAds) return;
    await showInterstitialIfEligible();
  }

  bool get isInterstitialEligible => isInterstitialEligibleAt(
        now: DateTime.now(),
        lastShownAt: _readLastInterstitialAt(),
        sessionStart: _sessionStart,
        readerWasOpenedThisSession: _readerWasOpenedThisSession,
        interstitialShownThisSession: _interstitialShownThisSession,
        cooldownMinutes: AppConfig.interstitialCooldownMinutes,
        minSessionMinutes: AppConfig.interstitialMinSessionMinutes,
        maxPerHour: AppConfig.interstitialMaxPerHour,
      );

  Future<void> showInterstitialIfEligible() async {
    if (!shouldShowAds || _isShowingInterstitial) return;
    if (!isInterstitialEligible) return;

    if (_interstitialAd == null) {
      await _preloadInterstitial();
    }

    final ad = _interstitialAd;
    if (ad == null) return;

    _isShowingInterstitial = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (dismissedAd) {
        dismissedAd.dispose();
        _interstitialAd = null;
        _isShowingInterstitial = false;
        _recordInterstitialShown();
        _preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (failedAd, error) {
        AppLogger.warning('Interstitial AdMob falhou ao exibir: $error');
        failedAd.dispose();
        _interstitialAd = null;
        _isShowingInterstitial = false;
        _preloadInterstitial();
      },
    );

    try {
      ad.show();
    } catch (e) {
      AppLogger.warning('Interstitial AdMob exceção ao exibir: $e');
      ad.dispose();
      _interstitialAd = null;
      _isShowingInterstitial = false;
    }
  }

  void _recordInterstitialShown() {
    final now = DateTime.now();
    _interstitialShownThisSession.add(now);
    storage.write(_keyLastInterstitialAtMs, now.millisecondsSinceEpoch);
  }

  DateTime? _readLastInterstitialAt() {
    return parseLastInterstitialAt(storage.read(_keyLastInterstitialAtMs));
  }

  Future<void> _preloadInterstitial() async {
    if (!shouldShowAds || _interstitialAd != null || _isLoadingInterstitial) {
      return;
    }

    _isLoadingInterstitial = true;
    await InterstitialAd.load(
      adUnitId: AppConfig.admobInterstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoadingInterstitial = false;
        },
        onAdFailedToLoad: (error) {
          AppLogger.warning('Interstitial AdMob falhou ao carregar: $error');
          _isLoadingInterstitial = false;
        },
      ),
    );
  }
}
