import 'package:equatable/equatable.dart';
import '../../domain/entities/product.dart';

abstract class CatalogEvent extends Equatable {
  const CatalogEvent();

  @override
  List<Object> get props => [];
}

class FetchCatalogProducts extends CatalogEvent {}

class AddCatalogProduct extends CatalogEvent {
  final Product product;

  const AddCatalogProduct(this.product);

  @override
  List<Object> get props => [product];
}

class UpdateCatalogProduct extends CatalogEvent {
  final Product product;

  const UpdateCatalogProduct(this.product);

  @override
  List<Object> get props => [product];
}

class DeleteCatalogProduct extends CatalogEvent {
  final String productId;

  const DeleteCatalogProduct(this.productId);

  @override
  List<Object> get props => [productId];
}

class FilterCatalogByCategory extends CatalogEvent {
  final String categoryName;

  const FilterCatalogByCategory(this.categoryName);

  @override
  List<Object> get props => [categoryName];
}

class FilterCatalogByGender extends CatalogEvent {
  final String gender;

  const FilterCatalogByGender(this.gender);

  @override
  List<Object> get props => [gender];
}

class SearchCatalog extends CatalogEvent {
  final String query;

  const SearchCatalog(this.query);

  @override
  List<Object> get props => [query];
}
