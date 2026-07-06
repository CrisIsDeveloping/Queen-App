import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../models/product_model.dart';
import '../../domain/entities/category.dart';
import '../models/category_model.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final SupabaseClient _supabaseClient;

  CatalogRepositoryImpl(this._supabaseClient);

  @override
  Future<List<Product>> getProducts({String? category, String? gender}) async {
    try {
      // Traemos todos los productos; el filtrado se hace localmente en CatalogBloc
      final response = await _supabaseClient
          .from('products')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Intentar con nombre alternativo de columna de fecha
      try {
        final response = await _supabaseClient
            .from('products')
            .select();
        return (response as List)
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e2) {
        throw Exception('Error al cargar el catálogo: $e2');
      }
    }
  }

  @override
  Future<void> insertProduct(Product product) async {
    try {
      final productModel = ProductModel(
        id: product.id,
        name: product.name,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        images: product.images,
        sheinUrl: product.sheinUrl,
        category: product.category,
        gender: product.gender,
        inStock: product.inStock,
      );

      await _supabaseClient.from('products').insert(productModel.toJson());
    } catch (e) {
      throw Exception('Error al insertar el producto: $e');
    }
  }

  @override
  Future<void> updateProduct(Product product) async {
    try {
      final productModel = ProductModel(
        id: product.id,
        name: product.name,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        images: product.images,
        sheinUrl: product.sheinUrl,
        category: product.category,
        gender: product.gender,
        inStock: product.inStock,
      );

      await _supabaseClient
          .from('products')
          .update(productModel.toJson())
          .eq('id', product.id);
    } catch (e) {
      throw Exception('Error al actualizar el producto: $e');
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      await _supabaseClient.from('products').delete().eq('id', productId);
    } catch (e) {
      throw Exception('Error al eliminar el producto: $e');
    }
  }

  @override
  Future<List<Category>> getCategories() async {
    try {
      // Ordenamos alfabéticamente o por id si se prefiere
      final response = await _supabaseClient
          .from('categories')
          .select()
          .order('name', ascending: true);
      
      final list = (response as List)
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return list.where((c) => c.name.toUpperCase() != 'NA').toList();
    } catch (e) {
      throw Exception('Error al cargar categorías: $e');
    }
  }

  @override
  Future<void> insertCategory(String name) async {
    try {
      await _supabaseClient.from('categories').insert({'name': name});
    } catch (e) {
      throw Exception('Error al crear la categoría: $e');
    }
  }

  @override
  Future<void> deleteCategory(String id, String categoryName) async {
    try {
      // 1. Movemos productos a NA
      await _supabaseClient
          .from('products')
          .update({'category': 'NA'})
          .eq('category', categoryName);

      // 2. Eliminamos la categoría
      await _supabaseClient.from('categories').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar la categoría: $e');
    }
  }
}
