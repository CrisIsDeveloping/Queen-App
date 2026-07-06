import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../catalog/domain/entities/product.dart';
import '../../../catalog/data/models/product_model.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _loading = true;
  List<Product> _favorites = [];
  final _user = Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    if (_user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      // Intento 1: Join directo (más eficiente si la relación está bien configurada en Supabase)
      final res = await Supabase.instance.client
          .from('favorites')
          .select('products(*)')
          .eq('user_id', _user!.id);

      final List<Product> products = [];
      for (final row in (res as List)) {
        final productData = row['products'];
        if (productData != null) {
          products.add(ProductModel.fromJson(productData as Map<String, dynamic>));
        }
      }
      setState(() {
        _favorites = products.where((p) => p.category.toUpperCase() != 'NA').toList();
        _loading = false;
      });
    } catch (e) {
      // Fallback 2 Pasos: Si el join falla (ej. error de PostgREST), traemos los IDs y luego los productos
      try {
        final favResponse = await Supabase.instance.client
            .from('favorites')
            .select('product_id')
            .eq('user_id', _user!.id);

        final List<dynamic> favRows = favResponse as List;
        if (favRows.isEmpty) {
          setState(() {
            _favorites = [];
            _loading = false;
          });
          return;
        }

        final productIds = favRows.map((r) => r['product_id'] as String).toList();
        final productsResponse = await Supabase.instance.client
            .from('products')
            .select()
            .inFilter('id', productIds);

        final List<Product> products = (productsResponse as List)
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();

        setState(() {
          _favorites = products.where((p) => p.category.toUpperCase() != 'NA').toList();
          _loading = false;
        });
      } catch (fallbackError) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis Favoritos', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.crimson,
        iconTheme: const IconThemeData(color: AppColors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.crimson))
          : _user == null
              ? _buildNotLoggedIn()
              : _favorites.isEmpty
                  ? _buildEmpty()
                  : _buildGrid(),
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text('Inicia sesión para ver tus favoritos',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.crimson,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Iniciar Sesión'),
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
          Icon(Icons.favorite_border, size: 64, color: AppColors.crimson.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'Aún no tienes favoritos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toca el corazón en cualquier producto\npara guardarlo aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.crimson,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Explorar Catálogo'),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final product = _favorites[index];
        return GestureDetector(
          onTap: () => context.push('/product', extra: product),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.crimson.withValues(alpha: 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: AppColors.borderLight, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.crimson),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.surfaceLight,
                        child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.crimson,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
