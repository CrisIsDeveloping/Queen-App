import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _user = Supabase.instance.client.auth.currentUser;
  bool _loading = false;
  String _fullName = '';
  String _avatarUrl = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (_user == null) return;
    setState(() => _loading = true);
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('user_id', _user!.id)
          .maybeSingle();

      if (data != null) {
        setState(() {
          _fullName = data['full_name'] as String? ?? '';
          _avatarUrl = data['avatar_url'] as String? ?? '';
        });
      }
    } catch (_) {
      // Ignorar error al cargar datos estéticos
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateProfile(String newName, String newAvatar) async {
    if (_user == null) return;
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.from('profiles').update({
        'full_name': newName.trim(),
        'avatar_url': newAvatar.trim().isEmpty ? null : newAvatar.trim(),
      }).eq('user_id', _user!.id);

      setState(() {
        _fullName = newName;
        _avatarUrl = newAvatar;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
          backgroundColor: AppColors.gold,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar perfil: $e'),
          backgroundColor: AppColors.crimson,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _changePassword(
      String currentPassword, String newPassword) async {
    setState(() => _loading = true);
    try {
      // Re-authenticate by signing in again with current password
      final email = _user?.email ?? '';
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
      // Now update to the new password
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña cambiada exitosamente'),
          backgroundColor: AppColors.gold,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.crimson,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<String?> _uploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 512, imageQuality: 80);
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

    await Supabase.instance.client.storage
        .from('avatars')
        .uploadBinary(fileName, bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'));

    final publicUrl = Supabase.instance.client.storage
        .from('avatars')
        .getPublicUrl(fileName);
    return publicUrl;
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _fullName);
    final avatarCtrl = TextEditingController(text: _avatarUrl);
    bool uploading = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Editar Perfil'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre Completo'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: avatarCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL de la Foto de Perfil',
                      hintText: 'https://...',
                    ),
                  ),
                  const SizedBox(height: 8),
                  uploading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(
                              color: AppColors.crimson, strokeWidth: 2),
                        )
                      : TextButton.icon(
                          icon: const Icon(Icons.photo_library_outlined,
                              color: AppColors.crimson),
                          label: const Text('Subir desde galería',
                              style: TextStyle(color: AppColors.crimson)),
                          onPressed: () async {
                            setDialogState(() => uploading = true);
                            try {
                              final url = await _uploadAvatar();
                              if (url != null) {
                                setDialogState(() {
                                  avatarCtrl.text = url;
                                  uploading = false;
                                });
                              } else {
                                setDialogState(() => uploading = false);
                              }
                            } catch (e) {
                              setDialogState(() => uploading = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('Error al subir imagen: $e'),
                                    backgroundColor: AppColors.crimson,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: uploading
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _updateProfile(nameCtrl.text, avatarCtrl.text);
                        },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.crimson,
                      foregroundColor: Colors.white),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Cambiar Contraseña'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña Actual',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Ingresa tu contraseña actual' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nueva Contraseña',
                    hintText: 'Mínimo 6 caracteres',
                    prefixIcon: Icon(Icons.lock_reset),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) {
                      return 'Mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Nueva Contraseña',
                    prefixIcon: Icon(Icons.check_circle_outline),
                  ),
                  validator: (v) {
                    if (v != newPassCtrl.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx);
                  _changePassword(
                      currentPassCtrl.text.trim(), newPassCtrl.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.crimson,
                  foregroundColor: Colors.white),
              child: const Text('Actualizar'),
            ),
          ],
        );
      },
    );
  }

  void _showNotificationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notificaciones'),
        content: const Text(
          'Las notificaciones push están actualmente activadas en este dispositivo para recibir alertas sobre tus pedidos y ofertas especiales.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido', style: TextStyle(color: AppColors.crimson)),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Términos y Condiciones',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.crimson),
              ),
              const SizedBox(height: 16),
              const Text(
                'Al utilizar App Queen, aceptas que recopilamos datos técnicos mínimos para mejorar la experiencia de usuario y procesar tus pedidos.\n\n'
                'Tus compras son gestionadas de forma segura. El pago se coordina directamente mediante las opciones brindadas al enviar tu correo de confirmación de pedido.\n\n'
                'Nos reservamos el derecho de modificar el catálogo, los precios y las promociones sin previo aviso.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.crimson,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Aceptar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Acerca de App Queen'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Queen - Catálogo Premium v1.0.0',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Desarrollada para ofrecer la mejor experiencia de compra, combinando elegancia, rapidez y gamificación para nuestros clientes más exclusivos.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textHint,
          letterSpacing: 1.0,
        ),
      ),
    );
  }



  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 0.5)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color ?? AppColors.textSecondary, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: color ?? AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint, size: 18),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Configuración', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.crimson,
        iconTheme: const IconThemeData(color: AppColors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.crimson))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildSectionHeader('Cuenta'),
                  _buildSettingsTile(
                    Icons.person_outline,
                    'Editar Perfil',
                    _showEditProfileDialog,
                  ),_buildSettingsTile(Icons.lock_outline, 'Cambiar Contraseña', _showChangePasswordDialog),
                  
                  _buildSectionHeader('Preferencias y Legal'),
                  _buildSettingsTile(Icons.notifications_none, 'Notificaciones', _showNotificationDialog),
                  _buildSettingsTile(Icons.gavel, 'Términos y Condiciones', _showTermsDialog),
                  _buildSettingsTile(Icons.info_outline, 'Acerca de la app', _showAboutDialog),
                  
                  const SizedBox(height: 32),
                  // Botón de cerrar sesión rojo destacado al final
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Cerrar Sesión'),
                              content: const Text('¿Estás seguro de que deseas salir?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
                                  child: const Text('Cerrar Sesión'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            if (!mounted) return;
                            this.context.read<AuthBloc>().add(AuthLogoutRequested());
                            this.context.go('/');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.crimson,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text(
                          'Cerrar Sesión',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
    );
  }
}
