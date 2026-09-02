import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:nrfacil/core/constants/app_config.dart';
import 'package:nrfacil/core/utils/app_logger.dart';

/// Banner AdMob para telas de lista (Favoritos, Todos, Busca).
///
/// Nunca usar no leitor de NR.
class ListBannerAd extends StatefulWidget {
  const ListBannerAd({super.key});

  @override
  State<ListBannerAd> createState() => _ListBannerAdState();
}

class _ListBannerAdState extends State<ListBannerAd> {
  BannerAd? _bannerAd;
  var _isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (!AppConfig.adsEnabled || kIsWeb) return;

    _bannerAd = BannerAd(
      adUnitId: AppConfig.admobBannerListUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          AppLogger.warning('Banner AdMob falhou: $error');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.adsEnabled || kIsWeb || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
