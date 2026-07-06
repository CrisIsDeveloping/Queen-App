import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic>? _profile;
  final _user = Supabase.instance.client.auth.currentUser;

  late AnimationController _progressAnimController;
  late AnimationController _fadeAnimController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _progressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _fadeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeAnimController,
      curve: Curves.easeOut,
    );
    _fetchProfile();
  }

  @override
  void dispose() {
    _progressAnimController.dispose();
    _fadeAnimController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    if (_user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('user_id', _user!.id)
          .maybeSingle();

      if (data == null) {
        await Supabase.instance.client.from('profiles').insert({
          'user_id': _user!.id,
          'full_name': _user!.email?.split('@').first ?? 'Usuario',
          'coins': 0,
          'level': 1,
          'streak_count': 1,
        });
        final created = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('user_id', _user!.id)
            .maybeSingle();
        setState(() {
          _profile = created;
          _loading = false;
        });
      } else {
        setState(() {
          _profile = data;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }

    // Start animations after data loads
    _progressAnimController.forward();
    _fadeAnimController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F8),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.crimson))
          : _user == null
              ? _buildNotLoggedIn()
              : _buildProfile(),
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text('No has iniciado sesión',
              style:
                  TextStyle(fontSize: 18, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/login'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crimson,
                foregroundColor: AppColors.white),
            child: const Text('Iniciar Sesión'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    final name =
        _profile?['full_name'] as String? ?? _user!.email ?? 'Usuario';
    final coins = _profile?['coins'] as int? ?? 0;
    final level = _profile?['level'] as int? ?? 1;
    final streakCount = _profile?['streak_count'] as int? ?? 1;
    final avatarUrl = _profile?['avatar_url'] as String?;

    final userEmail = _user?.email?.trim().toLowerCase();
    final adminEmails = (dotenv.env['ADMIN_EMAILS'] ?? '')
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .toList();
    final isAdmin = userEmail != null && adminEmails.contains(userEmail);

    // Calculate level progress
    int levelMin = 0;
    int levelMax = 50;
    String levelName = 'Principiante';
    String nextLevelLabel = 'Frecuente';
    String levelEmoji = '🌱';
    if (level == 2) {
      levelMin = 50;
      levelMax = 150;
      levelName = 'Frecuente';
      nextLevelLabel = 'VIP';
      levelEmoji = '⭐';
    } else if (level >= 3) {
      levelMin = 150;
      levelMax = 150;
      levelName = 'VIP';
      nextLevelLabel = '¡Máximo!';
      levelEmoji = '👑';
    }
    final progressInLevel =
        ((coins - levelMin) / (levelMax - levelMin)).clamp(0.0, 1.0);
    final coinsLeft = levelMax - coins;

    return FadeTransition(
      opacity: _fadeAnim,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Hero Header ───────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.crimson,
            iconTheme: const IconThemeData(color: AppColors.white),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push('/settings'),
                tooltip: 'Configuración',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF9B0035), AppColors.crimson, Color(0xFFD4005A)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      // Avatar
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.gold, width: 3),
                              color: AppColors.white.withValues(alpha: 0.15),
                              image: avatarUrl != null && avatarUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(avatarUrl),
                                      fit: BoxFit.cover)
                                  : null,
                            ),
                            child: avatarUrl == null || avatarUrl.isEmpty
                                ? const Icon(Icons.person,
                                    size: 52, color: AppColors.white)
                                : null,
                          ),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.white, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                isAdmin ? '💎' : levelEmoji,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _user!.email ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Streak badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: TweenAnimationBuilder<int>(
                          tween: IntTween(begin: 0, end: streakCount),
                          duration: const Duration(milliseconds: 1200),
                          builder: (ctx, v, _) => Text(
                            '🔥 $v ${v == 1 ? "día" : "días"} en racha',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAdmin) _buildAdminBadge() else ...[
                    // ─── Gamification card ───────────────────────
                    _buildGamificationCard(
                      level: level,
                      levelName: levelName,
                      levelEmoji: levelEmoji,
                      nextLevelLabel: nextLevelLabel,
                      coins: coins,
                      coinsLeft: coinsLeft,
                      progressInLevel: progressInLevel,
                    ),
                    const SizedBox(height: 12),
                      // ─── Monedas & Racha row ──────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _showInfoModal(
                              context,
                              '¿Cómo ganar monedas? 💰',
                              '• Gana 10 monedas por iniciar sesión cada día.\n• Gana monedas por cada compra que realices.\n• Usa tus monedas para obtener descuentos exclusivos.',
                            ),
                            borderRadius: BorderRadius.circular(18),
                            child: _buildStatTile(
                              icon: Icons.monetization_on,
                              color: const Color(0xFFFFA500),
                              label: 'Monedas',
                              animatedValue: coins,
                              suffix: '🪙',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatTile(
                            icon: Icons.local_fire_department,
                            color: Colors.deepOrange,
                            label: 'Días de racha',
                            animatedValue: streakCount,
                            suffix: '🔥',
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ─── Menu ─────────────────────────────────────
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'MI CUENTA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHint,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  _buildMenuSection([
                    _MenuEntry(Icons.favorite, 'Mis Favoritos',
                        AppColors.crimson, () => context.push('/favorites')),
                    _MenuEntry(Icons.shopping_bag_outlined, 'Mi Bolsa',
                        AppColors.gold, () => context.push('/cart')),
                    _MenuEntry(Icons.history, 'Mis Pedidos',
                        Colors.blueAccent, () => context.push('/orders')),
                    _MenuEntry(Icons.settings_outlined, 'Configuración',
                        AppColors.textSecondary,
                        () => context.push('/settings')),
                  ]),
                  const SizedBox(height: 12),
                  _buildMenuSection([
                    _MenuEntry(
                      Icons.logout,
                      'Cerrar Sesión',
                      AppColors.crimson,
                      () async {
                        await Supabase.instance.client.auth.signOut();
                        if (!mounted) return;
                        context.go('/');
                      },
                    ),
                  ]),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamificationCard({
    required int level,
    required String levelName,
    required String levelEmoji,
    required String nextLevelLabel,
    required int coins,
    required int coinsLeft,
    required double progressInLevel,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3D1A00), Color(0xFF8B4513)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NIVEL ACTUAL',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: level),
                      duration: const Duration(milliseconds: 1200),
                      builder: (ctx, v, _) => Row(
                        children: [
                          Text(
                            levelEmoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              levelName,
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Nivel badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'Lv. $level',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Progreso de experiencia',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (level < 3)
                Flexible(
                  child: Text(
                    'Faltan $coinsLeft 🪙 para $nextLevelLabel',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const Flexible(
                  child: Text(
                    '¡Nivel Máximo! 👑',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _progressAnimController,
            builder: (context, _) {
              final animated = Curves.easeOutCubic
                  .transform(_progressAnimController.value) * progressInLevel;
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        // Background track
                        Container(
                          height: 10,
                          width: double.infinity,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        // Progress fill with shimmer gradient
                        FractionallySizedBox(
                          widthFactor: animated,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                colors: [AppColors.gold, Color(0xFFFFE066)],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${(animated * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required Color color,
    required String label,
    required int animatedValue,
    required String suffix,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: animatedValue),
                  duration: const Duration(milliseconds: 1600),
                  curve: Curves.easeOutCubic,
                  builder: (ctx, v, _) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          '$v',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(suffix, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0x22FFA500),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield, color: AppColors.gold, size: 32),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cuenta de Administrador',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tienes privilegios para gestionar el catálogo, categorías y ventas de la tienda.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(List<_MenuEntry> entries) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: entries.asMap().entries.map((mapEntry) {
          final isLast = mapEntry.key == entries.length - 1;
          final entry = mapEntry.value;
          return Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: entry.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(entry.icon, color: entry.color, size: 20),
                ),
                title: Text(
                  entry.title,
                  style: TextStyle(
                    color: entry.color == AppColors.crimson &&
                            entry.title == 'Cerrar Sesión'
                        ? AppColors.crimson
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right,
                    color: AppColors.textHint, size: 20),
                onTap: entry.onTap,
              ),
              if (!isLast)
                const Divider(height: 1, indent: 60, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showInfoModal(BuildContext context, String title, String content) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Info',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (ctx, anim, secondAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
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
                colors: [Color(0xFFFFFFFF), Color(0xFFF9F9F9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top accent line
                Container(
                  height: 6,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.gold, Color(0xFFFFCC00)],
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    children: [
                      // Coin/Info icon with subtle pulse/circle
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gold.withValues(alpha: 0.12),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.35),
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text('🪙', style: TextStyle(fontSize: 36)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Content styled beautifully with proper spacing
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          content,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
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
                            '¡Entendido!',
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
}

class _MenuEntry {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  const _MenuEntry(this.icon, this.title, this.color, this.onTap);
}
