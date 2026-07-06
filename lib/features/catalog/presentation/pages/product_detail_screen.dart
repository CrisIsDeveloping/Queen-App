import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../../../core/theme/app_theme.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../domain/entities/product.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _isFavorite = false;
  bool _loadingFavorite = true;
  int _imageIndex = 0; // current page in the image carousel

  final PageController _pageController = PageController();
  Timer? _carouselTimer;
  List<String> _displayImages = [];

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    
    final hasMultipleImages = widget.product.images.length > 1;
    _displayImages = hasMultipleImages ? widget.product.images : [widget.product.imageUrl];
    
    if (_displayImages.length > 1) {
      _startCarouselTimer();
    }
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _imageIndex + 1;
        if (nextPage >= _displayImages.length) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onUserInteraction() {
    if (_displayImages.length > 1) {
      _startCarouselTimer();
    }
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkFavoriteStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _loadingFavorite = false);
      return;
    }
    try {
      final res = await Supabase.instance.client
          .from('favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('product_id', widget.product.id)
          .maybeSingle();
      setState(() {
        _isFavorite = res != null;
        _loadingFavorite = false;
      });
    } catch (_) {
      setState(() => _loadingFavorite = false);
    }
  }

  void _increment() => setState(() => _quantity++);

  void _decrement() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  bool _checkAuth() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Debes iniciar sesión para realizar esta acción'),
          backgroundColor: AppColors.crimson,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Entrar',
            textColor: AppColors.gold,
            onPressed: () => context.push('/login'),
          ),
        ),
      );
      return false;
    }
    return true;
  }

  void _addToBag() {
    if (!_checkAuth()) return;

    final cartBloc = context.read<CartBloc>();
    // Add product once per quantity unit (CartBloc increments by 1 each time)
    for (int i = 0; i < _quantity; i++) {
      cartBloc.add(AddToCart(widget.product));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${widget.product.name} (x$_quantity) añadido a la bolsa 🛍️'),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    if (!_checkAuth()) return;
    final user = Supabase.instance.client.auth.currentUser!;
    setState(() => _loadingFavorite = true);
    try {
      if (_isFavorite) {
        await Supabase.instance.client
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('product_id', widget.product.id);
        setState(() => _isFavorite = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Eliminado de favoritos'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        await Supabase.instance.client.from('favorites').insert({
          'user_id': user.id,
          'product_id': widget.product.id,
        });
        setState(() => _isFavorite = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Añadido a favoritos! ❤️'),
              backgroundColor: Colors.pinkAccent,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar favoritos: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _loadingFavorite = false);
    }
  }

  void _share() {
    final text =
        '¡Mira este producto en App Queen!\n${widget.product.name} — \$${widget.product.price.toStringAsFixed(2)}'
        '${widget.product.sheinUrl.isNotEmpty ? '\n${widget.product.sheinUrl}' : ''}';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          _loadingFavorite
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.crimson),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? AppColors.crimson : AppColors.textPrimary,
                  ),
                  onPressed: _toggleFavorite,
                ),
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.textPrimary),
            onPressed: _share,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Image section: single or carousel ───
                  Builder(builder: (context) {
                    if (_displayImages.length == 1) {
                      // Single image
                      return SizedBox(
                        height: MediaQuery.of(context).size.height * 0.55,
                        width: double.infinity,
                        child: CachedNetworkImage(
                          imageUrl: _displayImages.first,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.crimson),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.surfaceLight,
                            child: const Center(
                              child: Icon(Icons.image_not_supported,
                                  size: 50, color: Colors.grey),
                            ),
                          ),
                        ),
                      );
                    }

                    // Multiple images → PageView carousel
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.55,
                      child: Stack(
                        children: [
                          GestureDetector(
                            onPanDown: (_) => _onUserInteraction(),
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: _displayImages.length,
                              onPageChanged: (i) {
                                setState(() => _imageIndex = i);
                                _onUserInteraction();
                              },
                              itemBuilder: (context, i) {
                                return CachedNetworkImage(
                                  imageUrl: _displayImages[i],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                        color: AppColors.crimson),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: AppColors.surfaceLight,
                                    child: const Center(
                                      child: Icon(Icons.image_not_supported,
                                          size: 50, color: Colors.grey),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Page indicator dots
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _displayImages.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 3),
                                  width: _imageIndex == i ? 18 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _imageIndex == i
                                        ? AppColors.crimson
                                        : Colors.white.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  // Info del producto
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${widget.product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.crimson,
                              ),
                            ),
                            // Badge de género
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.product.gender,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Badge de Stock / Preorder
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.product.isPreorder 
                                ? AppColors.gold.withValues(alpha: 0.1)
                                : Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: widget.product.isPreorder 
                                  ? AppColors.gold.withValues(alpha: 0.5)
                                  : Colors.green.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.product.isPreorder ? Icons.schedule : Icons.check_circle_outline,
                                size: 16,
                                color: widget.product.isPreorder ? AppColors.gold : Colors.green,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.product.isPreorder ? 'Bajo pedido (15-20 días)' : 'Entrega Inmediata',
                                style: TextStyle(
                                  color: widget.product.isPreorder ? AppColors.gold : Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          'Descripción',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.product.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Selector de Cantidad
                        Row(
                          children: [
                            const Text(
                              'Cantidad',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.borderLight),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 20),
                                    onPressed: _decrement,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                  ),
                                  Text(
                                    '$_quantity',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 20),
                                    onPressed: _increment,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Botón fijo abajo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _addToBag,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'AÑADIR A LA BOLSA',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
