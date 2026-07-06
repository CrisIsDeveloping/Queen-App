import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/catalog/domain/repositories/catalog_repository.dart';
import '../../features/catalog/data/repositories/catalog_repository_impl.dart';
import '../../features/catalog/presentation/bloc/catalog_bloc.dart';
import '../../features/catalog/presentation/bloc/category_bloc.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../router/app_router.dart';
import '../services/gamification_service.dart';

final sl = GetIt.instance; // sl stands for Service Locator

void setupDependencyInjection() {
  // Core External Services
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  sl.registerLazySingleton<GamificationService>(() => GamificationService(sl<SupabaseClient>()));
  
  // Features - Auth
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<SupabaseClient>()),
  );
  
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(authRepository: sl<AuthRepository>()),
  );
  
  sl.registerLazySingleton<AppRouter>(
    () => AppRouter(sl<AuthBloc>()),
  );

  // Features - Catalog
  sl.registerLazySingleton<CatalogRepository>(
    () => CatalogRepositoryImpl(sl<SupabaseClient>()),
  );
  
  sl.registerLazySingleton<CatalogBloc>(
    () => CatalogBloc(catalogRepository: sl<CatalogRepository>()),
  );

  sl.registerLazySingleton<CategoryBloc>(
    () => CategoryBloc(catalogRepository: sl<CatalogRepository>()),
  );

  // Features - Cart
  sl.registerLazySingleton<CartBloc>(
    () => CartBloc(),
  );
}
