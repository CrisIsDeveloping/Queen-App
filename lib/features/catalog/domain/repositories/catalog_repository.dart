import '../entities/product.dart';
import '../entities/category.dart';

abstract class CatalogRepository {
  Future<List<Product>> getProducts({String? category, String? gender});
  Future<void> insertProduct(Product product);
  Future<void> updateProduct(Product product);

  Future<List<Category>> getCategories();
  Future<void> insertCategory(String name);
  Future<void> deleteCategory(String id, String categoryName);
}
