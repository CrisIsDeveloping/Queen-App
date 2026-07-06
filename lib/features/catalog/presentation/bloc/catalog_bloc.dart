import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/catalog_repository.dart';
import 'catalog_event.dart';
import 'catalog_state.dart';

class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  final CatalogRepository _catalogRepository;

  CatalogBloc({required CatalogRepository catalogRepository})
      : _catalogRepository = catalogRepository,
        super(CatalogInitial()) {
    on<FetchCatalogProducts>(_onFetchCatalogProducts);
    on<AddCatalogProduct>(_onAddCatalogProduct);
    on<UpdateCatalogProduct>(_onUpdateCatalogProduct);
    on<FilterCatalogByCategory>(_onFilterCatalogByCategory);
    on<FilterCatalogByGender>(_onFilterCatalogByGender);
    on<SearchCatalog>(_onSearchCatalog);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Aplica género, categoría y búsqueda sobre [all] y devuelve la lista filtrada.
  List<Product> _applyFilters(
    List<Product> all, {
    required String gender,
    required String category,
    String query = '',
  }) {
    // Excluir productos con categoría "NA" del catálogo público
    Iterable<Product> result = all.where((p) => p.category.toUpperCase() != 'NA');

    if (gender != 'Todos') {
      result = result.where((p) =>
          p.gender.toLowerCase() == gender.toLowerCase() ||
          p.gender.toLowerCase() == 'unisex');
    }

    if (category != 'Todo') {
      result = result.where(
          (p) => p.category.toLowerCase() == category.toLowerCase());
    }

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q));
    }

    return result.toList();
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _onFetchCatalogProducts(
      FetchCatalogProducts event, Emitter<CatalogState> emit) async {
    emit(CatalogLoading());
    try {
      // Traemos TODOS los productos sin filtros remotos
      final products = await _catalogRepository.getProducts();
      // Para la vista inicial del catálogo público, filtramos los que están en NA
      final filteredForCatalog = products.where((p) => p.category.toUpperCase() != 'NA').toList();
      emit(CatalogLoaded(filteredForCatalog, products, 'Todo', 'Todos'));
    } catch (e) {
      emit(CatalogError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAddCatalogProduct(
      AddCatalogProduct event, Emitter<CatalogState> emit) async {
    try {
      await _catalogRepository.insertProduct(event.product);
      add(FetchCatalogProducts());
    } catch (e) {
      emit(CatalogError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateCatalogProduct(
      UpdateCatalogProduct event, Emitter<CatalogState> emit) async {
    try {
      await _catalogRepository.updateProduct(event.product);
      add(FetchCatalogProducts());
    } catch (e) {
      emit(CatalogError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Filtrado LOCAL por categoría — no llama a la BD.
  Future<void> _onFilterCatalogByCategory(
      FilterCatalogByCategory event, Emitter<CatalogState> emit) async {
    if (state is! CatalogLoaded) return;
    final loaded = state as CatalogLoaded;

    final filtered = _applyFilters(
      loaded.allProducts,
      gender: loaded.selectedGender,
      category: event.categoryName,
    );

    emit(CatalogLoaded(
      filtered,
      loaded.allProducts,
      event.categoryName,
      loaded.selectedGender,
    ));
  }

  /// Filtrado LOCAL por género — no llama a la BD.
  Future<void> _onFilterCatalogByGender(
      FilterCatalogByGender event, Emitter<CatalogState> emit) async {
    if (state is! CatalogLoaded) return;
    final loaded = state as CatalogLoaded;

    final filtered = _applyFilters(
      loaded.allProducts,
      gender: event.gender,
      category: loaded.selectedCategory,
    );

    emit(CatalogLoaded(
      filtered,
      loaded.allProducts,
      loaded.selectedCategory,
      event.gender,
    ));
  }

  /// Búsqueda LOCAL por texto — no llama a la BD.
  Future<void> _onSearchCatalog(
      SearchCatalog event, Emitter<CatalogState> emit) async {
    if (state is! CatalogLoaded) return;
    final loaded = state as CatalogLoaded;

    final filtered = _applyFilters(
      loaded.allProducts,
      gender: loaded.selectedGender,
      category: loaded.selectedCategory,
      query: event.query,
    );

    emit(CatalogLoaded(
      filtered,
      loaded.allProducts,
      loaded.selectedCategory,
      loaded.selectedGender,
    ));
  }
}
