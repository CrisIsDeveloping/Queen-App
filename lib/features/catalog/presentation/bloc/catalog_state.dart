import 'package:equatable/equatable.dart';
import '../../domain/entities/product.dart';

abstract class CatalogState extends Equatable {
  const CatalogState();
  
  @override
  List<Object> get props => [];
}

class CatalogInitial extends CatalogState {}

class CatalogLoading extends CatalogState {}

class CatalogLoaded extends CatalogState {
  final List<Product> displayedProducts;
  final List<Product> allProducts;
  final String selectedCategory;
  final String selectedGender;

  const CatalogLoaded(this.displayedProducts, this.allProducts, this.selectedCategory, this.selectedGender);

  @override
  List<Object> get props => [displayedProducts, allProducts, selectedCategory, selectedGender];
}

class CatalogError extends CatalogState {
  final String message;

  const CatalogError(this.message);

  @override
  List<Object> get props => [message];
}
