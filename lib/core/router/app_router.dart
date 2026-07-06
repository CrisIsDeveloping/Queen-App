import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/register_screen.dart';
import '../../features/catalog/presentation/pages/catalog_screen.dart';
import '../../features/cart/presentation/pages/cart_screen.dart';
import '../../features/admin/presentation/pages/admin_dashboard_screen.dart';
import '../../features/catalog/domain/entities/product.dart';
import '../../features/catalog/presentation/pages/product_detail_screen.dart';
import '../../features/catalog/presentation/pages/favorites_screen.dart';
import '../../features/auth/presentation/pages/profile_screen.dart';
import '../../features/cart/presentation/pages/checkout_success_screen.dart';
import '../../features/auth/presentation/pages/order_history_screen.dart';
import '../../features/auth/presentation/pages/settings_screen.dart';

// Rutas que requieren autenticación
const _protectedRoutes = ['/checkout', '/admin'];

class AppRouter {
  final AuthBloc authBloc;

  AppRouter(this.authBloc);

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = authBloc.state;
      final bool isAuthenticated = authState is Authenticated;
      
      // state.uri.path previene el Assertion Error de state.matchedLocation
      final String location = state.uri.path;

      // 1. Verificar si la ruta requiere autenticación
      final bool isProtected = _protectedRoutes.any((r) => location.startsWith(r));
      
      if (isProtected && !isAuthenticated) {
        return '/login';
      }

      // 1.5. Verificar si es la ruta de Admin y si el usuario es Admin
      if (location.startsWith('/admin')) {
        if (authState is Authenticated) {
          final userEmail = authState.user.email?.trim().toLowerCase();
          final adminEmails = (dotenv.env['ADMIN_EMAILS'] ?? '')
              .split(',')
              .map((e) => e.trim().toLowerCase())
              .toList();
          if (userEmail == null || !adminEmails.contains(userEmail)) {
            return '/'; // No es admin, expulsar
          }
        } else {
          return '/login';
        }
      }

      // 2. Si ya está logueado y trata de ir a login o registro, enviarlo a la raíz
      if (isAuthenticated && (location == '/login' || location == '/register')) {
        return '/';
      }

      // 3. En cualquier otro caso (como '/'), no redirigir a ningún lado (público)
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const CatalogScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/product',
        builder: (context, state) => ProductDetailScreen(product: state.extra as Product),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/checkout-success',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CheckoutSuccessScreen(
            userName: extra['userName'] as String? ?? 'Usuario',
            total: extra['total'] as double? ?? 0.0,
            items: (extra['items'] as List).cast<Map<String, dynamic>>(),
            coinsEarned: extra['coinsEarned'] as int? ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
