import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Sin Nombre',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      // 'id' se autogenera en Supabase en el insert, así que lo omitimos si está vacío.
      if (id.isNotEmpty) 'id': id,
    };
  }
}
