import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/catalog_repository.dart';
import 'category_event.dart';
import 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CatalogRepository _catalogRepository;

  CategoryBloc({required CatalogRepository catalogRepository})
      : _catalogRepository = catalogRepository,
        super(CategoryInitial()) {
    on<FetchCategories>(_onFetchCategories);
    on<AddCategory>(_onAddCategory);
    on<DeleteCategory>(_onDeleteCategory);
  }

  Future<void> _onFetchCategories(FetchCategories event, Emitter<CategoryState> emit) async {
    emit(CategoryLoading());
    try {
      final categories = await _catalogRepository.getCategories();
      final filtered = categories.where((c) => c.name.toUpperCase() != 'NA').toList();
      emit(CategoryLoaded(filtered));
    } catch (e) {
      emit(CategoryError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAddCategory(AddCategory event, Emitter<CategoryState> emit) async {
    try {
      await _catalogRepository.insertCategory(event.name);
      add(FetchCategories());
    } catch (e) {
      emit(CategoryError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteCategory(DeleteCategory event, Emitter<CategoryState> emit) async {
    try {
      await _catalogRepository.deleteCategory(event.id, event.name);
      add(FetchCategories());
    } catch (e) {
      emit(CategoryError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
