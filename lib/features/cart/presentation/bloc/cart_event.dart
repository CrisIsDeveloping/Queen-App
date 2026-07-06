import 'package:equatable/equatable.dart';
import '../../../catalog/domain/entities/product.dart';
import '../../data/models/cart_item_model.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object> get props => [];
}

class AddToCart extends CartEvent {
  final Product product;

  const AddToCart(this.product);

  @override
  List<Object> get props => [product];
}

class RemoveFromCart extends CartEvent {
  final CartItemModel item;

  const RemoveFromCart(this.item);

  @override
  List<Object> get props => [item];
}

class UpdateQuantity extends CartEvent {
  final CartItemModel item;
  final int quantity;

  const UpdateQuantity(this.item, this.quantity);

  @override
  List<Object> get props => [item, quantity];
}

class ClearCart extends CartEvent {}
