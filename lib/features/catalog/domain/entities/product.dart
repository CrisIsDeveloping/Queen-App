import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;   // primera imagen (backward-compat)
  final List<String> images; // lista completa (nueva columna DB)
  final String sheinUrl;
  final String category;
  final String gender;
  final bool inStock;
  final bool isPreorder; // true = Bajo pedido (15-20 días), false = En físico

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.images = const [],
    required this.sheinUrl,
    required this.category,
    required this.gender,
    required this.inStock,
    this.isPreorder = false,
  });

  @override
  List<Object?> get props =>
      [id, name, description, price, imageUrl, images, sheinUrl, category, gender, inStock, isPreorder];
}
