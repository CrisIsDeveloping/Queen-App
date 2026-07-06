import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/cart_item_model.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<UpdateQuantity>(_onUpdateQuantity);
    on<ClearCart>(_onClearCart);
  }

  void _onAddToCart(AddToCart event, Emitter<CartState> emit) {
    final state = this.state;
    final productIndex = state.items.indexWhere((item) => item.product.id == event.product.id);

    if (productIndex >= 0) {
      // Producto ya en el carrito, incrementar cantidad
      final currentItem = state.items[productIndex];
      final List<CartItemModel> updatedItems = List.from(state.items);
      updatedItems[productIndex] = currentItem.copyWith(quantity: currentItem.quantity + 1);
      emit(state.copyWith(items: updatedItems));
    } else {
      // Producto nuevo, añadir al final
      final List<CartItemModel> updatedItems = List.from(state.items)..add(CartItemModel(product: event.product));
      emit(state.copyWith(items: updatedItems));
    }
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<CartState> emit) {
    final state = this.state;
    final List<CartItemModel> updatedItems = List.from(state.items)
      ..removeWhere((item) => item.product.id == event.item.product.id);
    
    emit(state.copyWith(items: updatedItems));
  }

  void _onUpdateQuantity(UpdateQuantity event, Emitter<CartState> emit) {
    if (event.quantity <= 0) {
      add(RemoveFromCart(event.item));
      return;
    }

    final state = this.state;
    final productIndex = state.items.indexWhere((item) => item.product.id == event.item.product.id);

    if (productIndex >= 0) {
      final List<CartItemModel> updatedItems = List.from(state.items);
      updatedItems[productIndex] = event.item.copyWith(quantity: event.quantity);
      emit(state.copyWith(items: updatedItems));
    }
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(const CartState(items: []));
  }
}
