import 'package:equatable/equatable.dart';
import '../../../catalog/domain/entities/product.dart';

class CartItemModel extends Equatable {
  final Product product;
  final int quantity;

  const CartItemModel({
    required this.product,
    this.quantity = 1,
  });

  CartItemModel copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  double get totalPrice => product.price * quantity;

  @override
  List<Object> get props => [product, quantity];
}
