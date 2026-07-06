import 'package:equatable/equatable.dart';
import '../../data/models/cart_item_model.dart';

class CartState extends Equatable {
  final List<CartItemModel> items;

  const CartState({this.items = const []});

  double get totalPrice {
    return items.fold<double>(0.0, (total, current) => total + current.totalPrice);
  }

  int get totalItems {
    return items.fold<int>(0, (total, current) => total + current.quantity);
  }

  CartState copyWith({
    List<CartItemModel>? items,
  }) {
    return CartState(
      items: items ?? this.items,
    );
  }

  @override
  List<Object> get props => [items];
}
