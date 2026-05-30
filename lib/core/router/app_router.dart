import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/auth/auth_state.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/forgot_password_page.dart';
import '../../presentation/pages/auth/otp_page.dart';
import '../../presentation/pages/admin/dashboard/dashboard_page.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String otp = '/otp';
  static const String dashboard = '/dashboard';

  static GoRouter router(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: splash,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final isOnSplash = state.matchedLocation == splash;
        final isOnAuth = state.matchedLocation == login ||
            state.matchedLocation == forgotPassword ||
            state.matchedLocation == otp;

        if (authState is AuthLoading || authState is AuthInitial) {
          return isOnSplash ? null : splash;
        }

        if (authState is AuthAuthenticated) {
          return isOnAuth || isOnSplash ? dashboard : null;
        }

        if (authState is AuthUnauthenticated) {
          return isOnAuth ? null : login;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: splash,
          name: 'splash',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: login,
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: forgotPassword,
          name: 'forgotPassword',
          builder: (context, state) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: otp,
          name: 'otp',
          builder: (context, state) => OtpPage(
            email: state.extra as String? ?? '',
          ),
        ),
        GoRoute(
          path: dashboard,
          name: 'dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
      ],
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}