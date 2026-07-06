import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.imageUrl,
    super.images = const [],
    required super.sheinUrl,
    required super.category,
    required super.gender,
    required super.inStock,
    super.isPreorder = false,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Producto sin nombre',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'] as String? ?? '',
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      sheinUrl: json['shein_url'] as String? ?? '',
      category: json['category'] as String? ?? 'Sin Categoría',
      gender: json['gender'] as String? ?? 'Unisex',
      inStock: json['in_stock'] as bool? ?? true,
      isPreorder: json['is_preorder'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'images': images,
      'shein_url': sheinUrl,
      'category': category,
      'gender': gender,
      'in_stock': inStock,
      'is_preorder': isPreorder,
      // 'id' se autogenera en Supabase en el insert, así que lo omitimos o lo enviamos solo si no está vacío.
      if (id.isNotEmpty) 'id': id,
    };
  }
}
