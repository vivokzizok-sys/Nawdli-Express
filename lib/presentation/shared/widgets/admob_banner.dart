import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/admob_config.dart';

class AdMobBanner extends StatelessWidget {
  final String placement;

  const AdMobBanner({super.key, required this.placement});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('app_config')
          .doc('ads')
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? const <String, dynamic>{};
        final enabled = data['enabled'] as bool? ?? true;
        final bannerEnabled = data['bannerEnabled'] as bool? ?? true;
        final testMode = data['testMode'] as bool? ?? false;
        final placements =
            data['placements'] as Map<String, dynamic>? ?? const {};
        final placementEnabled = placements[placement] as bool? ?? true;
        if (!enabled || !bannerEnabled || !placementEnabled) {
          return const SizedBox.shrink();
        }

        final configuredUnit = (data['bannerUnitId'] as String?)?.trim();
        final unitId = testMode
            ? AdMobConfig.testBannerUnitId
            : configuredUnit != null && configuredUnit.isNotEmpty
                ? configuredUnit
                : AdMobConfig.productionBannerUnitId;

        return _LoadedAdMobBanner(
          key: ValueKey('$placement-$unitId'),
          unitId: unitId,
        );
      },
    );
  }
}

class _LoadedAdMobBanner extends StatefulWidget {
  final String unitId;

  const _LoadedAdMobBanner({super.key, required this.unitId});

  @override
  State<_LoadedAdMobBanner> createState() => _LoadedAdMobBannerState();
}

class _LoadedAdMobBannerState extends State<_LoadedAdMobBanner> {
  BannerAd? _bannerAd;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final ad = BannerAd(
      size: AdSize.banner,
      adUnitId: widget.unitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdMob banner failed to load: $error');
          ad.dispose();
        },
      ),
    );
    ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          border: Border(
            bottom: BorderSide(color: AppColors.border(context)),
          ),
        ),
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
