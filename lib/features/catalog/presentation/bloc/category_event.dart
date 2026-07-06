import 'package:equatable/equatable.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object> get props => [];
}

class FetchCategories extends CategoryEvent {}

class AddCategory extends CategoryEvent {
  final String name;
  const AddCategory(this.name);
  
  @override
  List<Object> get props => [name];
}

class DeleteCategory extends CategoryEvent {
  final String id;
  final String name;
  const DeleteCategory({required this.id, required this.name});
  
  @override
  List<Object> get props => [id, name];
}
