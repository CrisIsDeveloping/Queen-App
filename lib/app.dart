import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/dependency_injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/catalog/presentation/bloc/catalog_bloc.dart';
import 'features/catalog/presentation/bloc/category_bloc.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';

class AppQueen extends StatelessWidget {
  const AppQueen({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = sl<AppRouter>().router;

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>(),
        ),
        BlocProvider<CatalogBloc>(
          create: (_) => sl<CatalogBloc>(),
        ),
        BlocProvider<CategoryBloc>(
          create: (_) => sl<CategoryBloc>(),
        ),
        BlocProvider<CartBloc>(
          create: (_) => sl<CartBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Queen Bodys Boutique',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
      ),
    );
  }
}
