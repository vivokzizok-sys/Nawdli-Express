import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_text_styles.dart';
import 'core/router/app_router.dart';
import 'core/settings/app_settings.dart';
import 'core/services/location_service.dart';
import 'core/services/notification_service.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/order_repository_impl.dart';
import 'data/repositories/tracking_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/order_repository.dart';
import 'domain/repositories/tracking_repository.dart';
import 'firebase_options.dart';
import 'presentation/auth/bloc/auth_bloc.dart';
import 'presentation/order/bloc/order_bloc.dart';
import 'presentation/tracking/bloc/tracking_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(MobileAds.instance.initialize());
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
    statusBarColor: Colors.transparent,
  ));

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const NawdliExpressApp());
}

class NawdliExpressApp extends StatefulWidget {
  const NawdliExpressApp({super.key});

  @override
  State<NawdliExpressApp> createState() => _NawdliExpressAppState();
}

class _NawdliExpressAppState extends State<NawdliExpressApp> {
  late final AuthRepository _authRepo;
  late final OrderRepository _orderRepo;
  late final TrackingRepository _trackingRepo;
  late final LocationService _locationSvc;
  late final NotificationService _notificationSvc;
  late final AppSettingsController _settingsController;

  late final AuthBloc _authBloc;
  late final OrderBloc _orderBloc;
  late final TrackingBloc _trackingBloc;
  late final router = AppRouter.createRouter(_authBloc);
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();

    _locationSvc = LocationService();
    _notificationSvc = NotificationService();
    _settingsController = AppSettingsController();
    _settingsController.load();
    _authRepo = AuthRepositoryImpl(
      auth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
    );
    _orderRepo = OrderRepositoryImpl(db: FirebaseFirestore.instance);
    _trackingRepo = TrackingRepositoryImpl(db: FirebaseFirestore.instance);

    _authBloc = AuthBloc(authRepository: _authRepo)..add(AuthCheckRequested());
    _orderBloc = OrderBloc(repository: _orderRepo);
    _trackingBloc = TrackingBloc(
      trackingRepository: _trackingRepo,
      locationService: _locationSvc,
    );

    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await _notificationSvc.initialize(onTap: _handleNotificationTap);
    final current = _authBloc.state;
    if (current is AuthAuthenticated) {
      await _notificationSvc.watchUserNotifications(current.user.uid);
    }
    _authSub = _authBloc.stream.listen((state) async {
      if (state is AuthAuthenticated) {
        await _notificationSvc.watchUserNotifications(state.user.uid);
      } else {
        await _notificationSvc.stopWatching();
      }
    });
  }

  void _handleNotificationTap(String? orderId) {
    if (orderId == null || orderId.isEmpty) return;
    router.go('/order/$orderId');
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _authBloc.close();
    _orderBloc.close();
    _trackingBloc.close();
    _locationSvc.dispose();
    _notificationSvc.dispose();
    _settingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<OrderBloc>.value(value: _orderBloc),
        BlocProvider<TrackingBloc>.value(value: _trackingBloc),
      ],
      child: AppSettingsScope(
        controller: _settingsController,
        child: AnimatedBuilder(
          animation: _settingsController,
          builder: (context, _) {
            return MaterialApp.router(
              title: 'Nawdli Express',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: _settingsController.themeMode,
              locale: _settingsController.locale,
              supportedLocales: const [Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) => Directionality(
                textDirection: _settingsController.textDirection,
                child: _IntroGate(
                  child:
                      _ForceUpdateGate(child: child ?? const SizedBox.shrink()),
                ),
              ),
              routerConfig: router,
            );
          },
        ),
      ),
    );
  }
}

class _IntroGate extends StatefulWidget {
  final Widget child;

  const _IntroGate({required this.child});

  @override
  State<_IntroGate> createState() => _IntroGateState();
}

class _IntroGateState extends State<_IntroGate> {
  static const _fallbackIntroDuration = Duration(seconds: 4);

  VideoPlayerController? _controller;
  Timer? _fallbackTimer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _playIntro();
  }

  Future<void> _playIntro() async {
    final controller = VideoPlayerController.asset('assets/videos/intro.mp4');
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.play();
      final videoDuration = controller.value.duration;
      _fallbackTimer = Timer(
        videoDuration > Duration.zero
            ? videoDuration + const Duration(milliseconds: 300)
            : _fallbackIntroDuration,
        _finish,
      );
      controller.addListener(() {
        if (controller.value.isCompleted) _finish();
      });
      if (mounted) setState(() {});
    } catch (_) {
      _fallbackTimer = Timer(_fallbackIntroDuration, _finish);
    }
  }

  void _finish() {
    if (_finished || !mounted) return;
    setState(() => _finished = true);
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return widget.child;
    final controller = _controller;
    return Material(
      color: AppColors.accentDark,
      child: SizedBox.expand(
        child: controller != null && controller.value.isInitialized
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              )
            : const Center(
                child: Text(
                  'Nawdli Express',
                  style: AppTextStyles.largeTitle,
                ),
              ),
      ),
    );
  }
}

class _ForceUpdateGate extends StatefulWidget {
  final Widget child;

  const _ForceUpdateGate({required this.child});

  @override
  State<_ForceUpdateGate> createState() => _ForceUpdateGateState();
}

class _ForceUpdateGateState extends State<_ForceUpdateGate> {
  static const _releaseApiUrl =
      'https://api.github.com/repos/vivokzizok-sys/Nawdli-Express/releases/tags/android-latest';
  static const _updateUrl = 'https://nawdli-express.web.app';
  static const _currentBuildNumber =
      int.fromEnvironment('APP_BUILD_NUMBER', defaultValue: 1);

  late final Future<_UpdateCheckResult> _updateCheck = _checkForUpdate();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_UpdateCheckResult>(
      future: _updateCheck,
      builder: (context, snap) {
        final result = snap.data;
        if (result?.mustUpdate != true) return widget.child;

        return Material(
          color: AppColors.page(context),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.system_update_rounded,
                        color: AppColors.accent, size: 42),
                    const SizedBox(height: 14),
                    Text(
                      context.t('update_required'),
                      style: AppTextStyles.title2.copyWith(
                        color: AppColors.textPrimary(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.t('update_required_body'),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse(result!.updateUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.download_rounded),
                      label: Text(context.t('download_update')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<_UpdateCheckResult> _checkForUpdate() async {
    try {
      final latest = await _fetchLatestRelease();
      return _UpdateCheckResult(
        mustUpdate: latest.buildNumber > _currentBuildNumber,
        updateUrl: latest.updateUrl,
      );
    } catch (_) {
      return const _UpdateCheckResult(mustUpdate: false, updateUrl: _updateUrl);
    }
  }

  Future<_LatestReleaseInfo> _fetchLatestRelease() async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(_releaseApiUrl));
      request.headers.set(HttpHeaders.userAgentHeader, 'Nawdli Express');
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        return const _LatestReleaseInfo(buildNumber: 0, updateUrl: _updateUrl);
      }
      final raw = await utf8.decoder.bind(response).join();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final body = decoded['body'] as String? ?? '';
      final buildMatch = RegExp(r'buildNumber:\s*(\d+)').firstMatch(body);
      final urlMatch = RegExp(r'updateUrl:\s*(\S+)').firstMatch(body);
      return _LatestReleaseInfo(
        buildNumber: int.tryParse(buildMatch?.group(1) ?? '') ?? 0,
        updateUrl: urlMatch?.group(1) ?? _updateUrl,
      );
    } finally {
      client.close(force: true);
    }
  }
}

class _UpdateCheckResult {
  final bool mustUpdate;
  final String updateUrl;

  const _UpdateCheckResult({
    required this.mustUpdate,
    required this.updateUrl,
  });
}

class _LatestReleaseInfo {
  final int buildNumber;
  final String updateUrl;

  const _LatestReleaseInfo({
    required this.buildNumber,
    required this.updateUrl,
  });
}
