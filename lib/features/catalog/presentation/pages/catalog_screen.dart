import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:marquee/marquee.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/catalog_bloc.dart';
import '../bloc/catalog_event.dart';
import '../bloc/catalog_state.dart';
import '../bloc/category_bloc.dart';
import '../bloc/category_event.dart';
import '../bloc/category_state.dart';
import '../widgets/product_card.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/services/gamification_service.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchController = TextEditingController();

  bool _hasCheckedStreak = false;

  @override
  void initState() {
    super.initState();
    context.read<CatalogBloc>().add(FetchCatalogProducts());
    context.read<CategoryBloc>().add(FetchCategories());
    
    // Si ya estaba autenticado al momento de cargar la pantalla (ej. Hot Restart o inicio normal)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialStreak();
    });
  }

  void _checkInitialStreak() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated && !_hasCheckedStreak) {
      _hasCheckedStreak = true;
      final gamificationService = sl<GamificationService>();
      final result = await gamificationService.checkDailyLogin(authState.user.id);
      if (result != null && mounted) {
        _showStreakDialog(result);
      }
    }
  }

  void _showStreakDialog(DailyStreakResult result) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Racha',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 450),
      transitionBuilder: (ctx, anim, secondAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.elasticOut);
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, _, __) => Dialog(
        backgroundColor: Colors.transparent,
        child: SingleChildScrollView(
          child: Container(
            clipBehavior: Clip.antiAlias,
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF1A0A00), Color(0xFF4A1A00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.4),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top gradient bar
                Container(
                  height: 6,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.gold, Color(0xFFFFE066)],
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  child: Column(
                    children: [
                      // Fire icon with glow
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gold.withValues(alpha: 0.15),
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 2),
                        ),
                        child: const Center(
                          child: Text('🔥', style: TextStyle(fontSize: 42)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        result.newStreakCount == 1
                            ? '¡Te damos la bienvenida!'
                            : '¡Racha de ${result.newStreakCount} días!',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.newStreakCount == 1
                            ? 'Tu primera visita del día. ¡Sigue así!'
                            : '¡Llevas ${result.newStreakCount} días consecutivos! 🏆',
                        style: const TextStyle(color: Colors.white60, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // Reward row
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.monetization_on, color: AppColors.gold, size: 28),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                '+${result.coinsEarned} Monedas obtenidas',
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.workspace_premium, color: Colors.white54, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Nivel ${result.newLevel}',
                              style: const TextStyle(color: Colors.white54, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            '¡Reclamar recompensa!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) async {
        if (authState is Authenticated && !_hasCheckedStreak) {
          _hasCheckedStreak = true;
          final gamificationService = sl<GamificationService>();
          final result = await gamificationService.checkDailyLogin(authState.user.id);
          if (result != null && mounted) {
            _showStreakDialog(result);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
      drawer: _buildDrawer(context),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(context),
        ],
        body: BlocBuilder<CatalogBloc, CatalogState>(
          builder: (context, state) {
            if (state is CatalogLoading || state is CatalogInitial) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.crimson),
              );
            } else if (state is CatalogError) {
              return _buildError(context, state.message);
            } else if (state is CatalogLoaded) {
              if (state.displayedProducts.isEmpty) {
                return _buildEmpty();
              }
              return _buildGrid(context, state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    ));
  }

  // ───────────────────────────────────────────────
  // DRAWER
  // ───────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.white,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final isAuthenticated = authState is Authenticated;
          final userId = isAuthenticated ? authState.user.id : null;
          final email = isAuthenticated ? authState.user.email ?? '' : '';

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.crimson, Color(0xFF7B0034)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isAuthenticated && userId != null)
                      FutureBuilder<Map<String, dynamic>?>(
                        future: supa.Supabase.instance.client
                            .from('profiles')
                            .select('full_name, avatar_url, streak_count')
                            .eq('user_id', userId)
                            .maybeSingle(),
                        builder: (context, snapshot) {
                          final displayName = snapshot.data?['full_name'] as String? ??
                              email.split('@').first;
                          final avatarUrl = snapshot.data?['avatar_url'] as String?;
                          final streak = snapshot.data?['streak_count'] as int? ?? 1;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar circle with photo or fallback icon
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.white.withValues(alpha: 0.15),
                                      border: Border.all(color: AppColors.gold, width: 2),
                                      image: avatarUrl != null && avatarUrl.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(avatarUrl),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: avatarUrl == null || avatarUrl.isEmpty
                                        ? const Icon(
                                            Icons.person,
                                            color: AppColors.white,
                                            size: 32,
                                          )
                                        : null,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text('🔥', style: TextStyle(fontSize: 16)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$streak',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                displayName,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                email,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        },
                      )
                    else ...[
                      // Guest avatar
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withValues(alpha: 0.15),
                          border: Border.all(color: AppColors.gold, width: 2),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: AppColors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Invitado/a',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                    if (!isAuthenticated)
                      TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.push('/login');
                        },
                        child: const Text(
                          'Iniciar Sesión / Registrarse',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              _drawerItem(context,
                  icon: Icons.person_outline,
                  label: 'Mi Cuenta',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/profile');
                  }),
              _drawerItem(context,
                  icon: Icons.favorite_border,
                  label: 'Mis Favoritos',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/favorites');
                  }),
              _drawerItem(context,
                  icon: Icons.shopping_bag_outlined,
                  label: 'Mi Bolsa',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/cart');
                  }),
              const Divider(),
              _drawerItem(context,
                  icon: Icons.mail_outline,
                  label: 'Contáctanos',
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Próximamente: formulario de contacto'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }),
              if (isAuthenticated)
                _drawerItem(context,
                    icon: Icons.logout,
                    label: 'Cerrar Sesión',
                    color: AppColors.crimson,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.read<AuthBloc>().add(AuthLogoutRequested());
                      context.go('/');
                    }),
            ],
          );
        },
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textPrimary),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
      onTap: onTap,
    );
  }

  // ───────────────────────────────────────────────
  // SLIVER APP BAR
  // Usa toolbarHeight:0 + todo en `bottom` PreferredSize
  // para que NestedScrollView calcule el offset correctamente
  // y el contenido NO se superponga con el header.
  // ───────────────────────────────────────────────
  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: const Color(0xFF111111),
      surfaceTintColor: Colors.transparent,
      pinned: true,
      floating: true,
      snap: true,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      // toolbarHeight:0 → el toolbar no ocupa espacio propio
      toolbarHeight: 0,
      // Todo el header vive aquí: 30 + 95 + 44 + 46 = 215px
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(215),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 1. Marquee ──────────────────────────────────────────────
            SizedBox(
              height: 30,
              child: ColoredBox(
                color: AppColors.crimson,
                child: Marquee(
                  text: '✨ COMPRA AHORA Y OBTÉN 20% DE DESCUENTO EN TU PRIMERA ORDEN ✨   '
                      'ENVÍO GRATIS EN PEDIDOS SUPERIORES A \$50 ✨   '
                      'OFERTAS EXCLUSIVAS DE TEMPORADA ✨   '
                      'DEVOLUCIONES GRATUITAS EN 30 DÍAS ✨   '
                      'PAGO 100% SEGURO ✨   ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                  scrollAxis: Axis.horizontal,
                  blankSpace: 60.0,
                  velocity: 50.0,
                  pauseAfterRound: const Duration(seconds: 1),
                  fadingEdgeStartFraction: 0.05,
                  fadingEdgeEndFraction: 0.05,
                ),
              ),
            ),

            // ── 2. Barra principal ──────────────────────────────────────
            Container(
              height: 95,
              color: const Color(0xFF111111),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Botón hamburguesa
                  GestureDetector(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.menu, color: Colors.white, size: 26),
                    ),
                  ),
                  // Logo
                  Image.asset(
                    'assets/images/logo_transparente.png',
                    height: 55,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 14),
                  // Buscador — Theme local anula el fillColor blanco del tema global
                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        inputDecorationTheme: const InputDecorationTheme(
                          filled: true,
                          fillColor: Color(0xFF2A2A2A),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          prefixIconColor: Color(0xFF888888),
                          hintStyle: TextStyle(color: Color(0xFF888888), fontSize: 13),
                          contentPadding: EdgeInsets.symmetric(vertical: 13),
                        ),
                        textSelectionTheme: const TextSelectionThemeData(
                          cursorColor: AppColors.crimson,
                          selectionColor: Color(0x44C8005A),
                          selectionHandleColor: AppColors.crimson,
                        ),
                      ),
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(21),
                          border: Border.all(color: Colors.white24, width: 0.8),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          cursorColor: AppColors.crimson,
                          decoration: const InputDecoration(
                            hintText: 'Buscar productos...',
                            hintStyle: TextStyle(color: Color(0xFF888888), fontSize: 13),
                            prefixIcon: Icon(Icons.search, color: Color(0xFF888888), size: 20),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: EdgeInsets.symmetric(vertical: 13),
                          ),
                          onChanged: (query) =>
                              context.read<CatalogBloc>().add(SearchCatalog(query)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Iconos de acción
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, authState) {
                      final isAuthenticated = authState is Authenticated;
                      final userEmail = isAuthenticated ? authState.user.email?.trim().toLowerCase() : null;
                      final adminEmails = (dotenv.env['ADMIN_EMAILS'] ?? '')
                          .split(',')
                          .map((e) => e.trim().toLowerCase())
                          .toList();
                      final isAdmin = isAuthenticated &&
                          userEmail != null &&
                          adminEmails.contains(userEmail);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isAdmin)
                            GestureDetector(
                              onTap: () => context.push('/admin'),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(Icons.admin_panel_settings,
                                    color: AppColors.gold, size: 26),
                              ),
                            ),
                          GestureDetector(
                            onTap: () => isAuthenticated
                                ? context.push('/profile')
                                : context.push('/login'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(
                                isAuthenticated ? Icons.person : Icons.person_outline,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  BlocBuilder<CartBloc, CartState>(
                    builder: (context, cartState) {
                      return GestureDetector(
                        onTap: () => context.push('/cart'),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.shopping_bag_outlined,
                                  color: Colors.white, size: 26),
                              if (cartState.totalItems > 0)
                                Positioned(
                                  right: -5,
                                  top: -5,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.crimson,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${cartState.totalItems}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── 3. Filtro de Géneros (44px) ─────────────────────────────
            BlocBuilder<CatalogBloc, CatalogState>(
              builder: (context, catalogState) {
                final selectedGender = catalogState is CatalogLoaded
                    ? catalogState.selectedGender
                    : 'Todos';
                return Container(
                  height: 44,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAFAFA),
                    border: Border(
                        bottom: BorderSide(color: AppColors.borderLight, width: 1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['Todos', 'Mujer', 'Hombre'].map((g) {
                      final isSelected = selectedGender == g;
                      return GestureDetector(
                        onTap: () => context
                            .read<CatalogBloc>()
                            .add(FilterCatalogByGender(g)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isSelected
                                    ? AppColors.crimson
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            g.toUpperCase(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isSelected
                                  ? AppColors.crimson
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),

            // ── 4. Filtro de Categorías (46px) ──────────────────────────
            BlocBuilder<CatalogBloc, CatalogState>(
              builder: (context, catalogState) {
                final selectedCategory = catalogState is CatalogLoaded
                    ? catalogState.selectedCategory
                    : 'Todo';
                return Container(
                  height: 46,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        bottom: BorderSide(color: AppColors.borderLight, width: 1)),
                  ),
                  child: BlocBuilder<CategoryBloc, CategoryState>(
                    builder: (context, categoryState) {
                      List<String> categories = ['Todo'];
                      if (categoryState is CategoryLoaded) {
                        categories
                            .addAll(categoryState.categories.map((c) => c.name));
                      }
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: categories.map((cat) {
                            return GestureDetector(
                              onTap: () => context
                                  .read<CatalogBloc>()
                                  .add(FilterCatalogByCategory(cat)),
                              child: _buildCategoryChip(
                                  cat, selectedCategory == cat),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.crimson : AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 30,
              color: AppColors.crimson,
            )
          else
            const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, CatalogLoaded state) {
    return RefreshIndicator(
      color: AppColors.crimson,
      onRefresh: () async {
        context.read<CatalogBloc>().add(FetchCatalogProducts());
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: state.displayedProducts.length,
        itemBuilder: (context, index) {
          final product = state.displayedProducts[index];
          return ProductCard(
            product: product,
            onAddToCart: () {
              context.read<CartBloc>().add(AddToCart(product));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} añadido'),
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: 'Ver carrito',
                    textColor: AppColors.gold,
                    onPressed: () => context.push('/cart'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: AppColors.crimson.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'Ups, algo salió mal',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textHint)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () =>
                context.read<CatalogBloc>().add(FetchCatalogProducts()),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo_transparente.png',
            height: 120,
            opacity: const AlwaysStoppedAnimation(0.15),
          ),
          const SizedBox(height: 20),
          const Text(
            'Próximamente nuevos ingresos',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textHint,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
