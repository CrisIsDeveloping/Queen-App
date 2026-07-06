import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/services/gamification_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isCheckingOut = false;

  void _onCheckout(CartState state) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para finalizar tu compra'),
          backgroundColor: AppColors.crimson,
          duration: Duration(seconds: 3),
        ),
      );
      context.push('/login');
      return;
    }

    setState(() => _isCheckingOut = true);

    try {
      // 1. Recoger todos los productos como JSON
      final itemsJson = state.items.map((item) => {
        'id': item.product.id,
        'name': item.product.name,
        'price': item.product.price,
        'image_url': item.product.imageUrl,
        'quantity': item.quantity,
      }).toList();

      // 2. Insertar en supabase
      await Supabase.instance.client.from('orders').insert({
        'user_id': user.id,
        'items': itemsJson,
        'total': state.totalPrice,
        'status': 'Pendiente',
      });

      // 2.5. Añadir monedas (5 por producto)
      final totalItems = itemsJson.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
      final coinsEarned = totalItems * 5;
      final gamificationService = sl<GamificationService>();
      await gamificationService.addCoinsAndCheckLevel(user.id, coinsEarned);

      // 3. Obtener el nombre del usuario
      final profileRes = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('user_id', user.id)
          .maybeSingle();
      final userName = profileRes?['full_name'] as String? ?? user.email?.split('@').first ?? 'Usuario';

      if (!mounted) return;

      // 4. Vaciar el carrito local
      context.read<CartBloc>().add(ClearCart());

      // 5. Ir a la pantalla de éxito
      context.go('/checkout-success', extra: {
        'userName': userName,
        'total': state.totalPrice,
        'items': itemsJson,
        'coinsEarned': coinsEarned,
      });

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar el pedido: $e'),
          backgroundColor: AppColors.crimson,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCheckingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: Row(
          children: [
            Image.asset('assets/images/logo_transparente.png', height: 32),
            const SizedBox(width: 10),
            const Text('Mi Bolsa'),
          ],
        ),
        actions: [
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state.items.isEmpty) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: _isCheckingOut
                    ? null
                    : () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Vaciar carrito'),
                            content: const Text('¿Segura que deseas eliminar todos los productos?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  context.read<CartBloc>().add(ClearCart());
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
                                child: const Text('Vaciar'),
                              ),
                            ],
                          ),
                        );
                      },
                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                label: const Text('Vaciar'),
                style: TextButton.styleFrom(foregroundColor: AppColors.crimson),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo_transparente.png',
                    height: 100,
                    opacity: const AlwaysStoppedAnimation(0.12),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Tu bolsa está vacía',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Añade prendas para comenzar',
                    style: TextStyle(color: AppColors.textHint),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Ver catálogo'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.crimson.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Imagen
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                            child: CachedNetworkImage(
                              imageUrl: item.product.imageUrl,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              placeholder: (c, u) => Container(
                                width: 90,
                                height: 90,
                                color: AppColors.surfaceLight,
                              ),
                              errorWidget: (c, u, e) => Container(
                                width: 90,
                                height: 90,
                                color: AppColors.surfaceLight,
                                child: Image.asset(
                                  'assets/images/logo_transparente.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Detalles
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${item.product.price.toStringAsFixed(2)} c/u',
                                    style: const TextStyle(
                                      color: AppColors.gold,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Stepper de cantidad
                                  Row(
                                    children: [
                                      _QtyButton(
                                        icon: Icons.remove,
                                        onTap: _isCheckingOut
                                            ? () {}
                                            : () => context.read<CartBloc>().add(
                                                  UpdateQuantity(item, item.quantity - 1),
                                                ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          '${item.quantity}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppColors.crimson,
                                          ),
                                        ),
                                      ),
                                      _QtyButton(
                                        icon: Icons.add,
                                        onTap: _isCheckingOut
                                            ? () {}
                                            : () => context.read<CartBloc>().add(
                                                  UpdateQuantity(item, item.quantity + 1),
                                                ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Eliminar y subtotal
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  color: AppColors.crimson.withValues(alpha: 0.6),
                                  onPressed: _isCheckingOut
                                      ? null
                                      : () =>
                                          context.read<CartBloc>().add(RemoveFromCart(item)),
                                ),
                                Text(
                                  '\$${item.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.crimson,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Panel de total y checkout
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.borderLight,
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Separador dorado decorativo
                      Container(
                        width: 40,
                        height: 3,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total a pagar',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '\$${state.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.crimson,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isCheckingOut ? null : () => _onCheckout(state),
                          icon: _isCheckingOut
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.shopping_bag_outlined),
                          label: Text(_isCheckingOut ? 'Procesando...' : 'Finalizar Compra'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.crimson),
      ),
    );
  }
}
