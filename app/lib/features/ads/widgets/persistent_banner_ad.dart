import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:nrfacil/core/constants/app_config.dart';
import 'package:nrfacil/core/utils/app_logger.dart';
import 'package:nrfacil/features/ads/services/ads_service.dart';

/// Banner AdMob fixo acima da bottom nav na Home (Normas / Favoritos / Buscar).
///
/// Nunca usar no leitor de NR.
class PersistentBannerAd extends StatefulWidget {
  const PersistentBannerAd({super.key});

  @override
  State<PersistentBannerAd> createState() => _PersistentBannerAdState();
}

class _PersistentBannerAdState extends State<PersistentBannerAd> {
  BannerAd? _bannerAd;
  var _isLoaded = false;
  var _isLoading = false;
  var _lastWidth = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBannerIfNeeded();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadBannerIfNeeded() async {
    if (!Get.isRegistered<AdsService>()) return;

    final adsService = Get.find<AdsService>();
    if (!adsService.shouldShowAds || kIsWeb) return;

    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width == _lastWidth && (_bannerAd != null || _isLoading)) return;

    _lastWidth = width;
    _bannerAd?.dispose();
    _isLoading = false;
    setState(() {
      _bannerAd = null;
      _isLoaded = false;
    });

    _isLoading = true;

    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null) {
      _isLoading = false;
      return;
    }

    final banner = BannerAd(
      adUnitId: AppConfig.admobBannerListUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
              _isLoading = false;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          AppLogger.warning('Banner AdMob falhou: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isLoaded = false;
              _isLoading = false;
            });
          }
        },
      ),
    );

    _bannerAd = banner;
    banner.load();
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AdsService>()) {
      return const SizedBox.shrink();
    }

    final adsService = Get.find<AdsService>();
    return Obx(() {
      if (!adsService.shouldShowAds || kIsWeb || !_isLoaded || _bannerAd == null) {
        return const SizedBox.shrink();
      }

      final colorScheme = Theme.of(context).colorScheme;
      final banner = _bannerAd!;

      return ColoredBox(
        color: colorScheme.surface,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.45),
              ),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            height: banner.size.height.toDouble(),
            child: Center(
              child: SizedBox(
                width: banner.size.width.toDouble(),
                height: banner.size.height.toDouble(),
                child: AdWidget(ad: banner),
              ),
            ),
          ),
        ),
      );
    });
  }
}
