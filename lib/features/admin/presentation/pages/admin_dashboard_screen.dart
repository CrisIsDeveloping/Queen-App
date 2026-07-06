import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../catalog/domain/entities/product.dart';
import '../../../catalog/presentation/bloc/catalog_bloc.dart';
import '../../../catalog/presentation/bloc/catalog_event.dart';
import '../../../catalog/presentation/bloc/catalog_state.dart';
import '../../../catalog/presentation/bloc/category_bloc.dart';
import '../../../catalog/presentation/bloc/category_event.dart';
import '../../../catalog/presentation/bloc/category_state.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Formularios
  final _productFormKey = GlobalKey<FormState>();
  final _categoryFormKey = GlobalKey<FormState>();
  
  // Controladores Producto
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  List<String> _productImages = [];
  final _sheinUrlController = TextEditingController();
  
  // Controladores Categoría
  final _categoryNameController = TextEditingController();

  String? _selectedCategory;
  String? _selectedGender = 'Mujer';
  bool _inStock = true;
  bool _isPreorder = false;

  Future<List<Map<String, dynamic>>>? _ordersFuture;

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(FetchCategories());
    _ordersFuture = _loadOrders();
  }

  Future<List<Map<String, dynamic>>> _loadOrders() async {
    // Helper to safely convert any Supabase map to Map<String, dynamic>
    Map<String, dynamic> toSafe(dynamic raw) =>
        Map<String, dynamic>.from(raw as Map);

    try {
      // Attempt 1: join using FK hint
      final res = await Supabase.instance.client
          .from('orders')
          .select('*, profiles!user_id(full_name)')
          .order('created_at', ascending: false);
      return (res as List).map((e) {
        final order = toSafe(e);
        final rawProfile = order['profiles'];
        if (rawProfile != null) {
          order['profiles'] = toSafe(rawProfile);
        }
        return order;
      }).toList();
    } catch (_) {
      try {
        // Attempt 2: simpler join
        final res = await Supabase.instance.client
            .from('orders')
            .select('*, profiles(full_name)')
            .order('created_at', ascending: false);
        return (res as List).map((e) {
          final order = toSafe(e);
          final rawProfile = order['profiles'];
          if (rawProfile != null) {
            order['profiles'] = toSafe(rawProfile);
          }
          return order;
        }).toList();
      } catch (_) {
        // Attempt 3: manual profile merge
        final res = await Supabase.instance.client
            .from('orders')
            .select()
            .order('created_at', ascending: false);

        final ordersList = (res as List).map(toSafe).toList();
        if (ordersList.isEmpty) return ordersList;

        final userIds =
            ordersList.map((o) => o['user_id'] as String).toSet().toList();
        final profilesRes = await Supabase.instance.client
            .from('profiles')
            .select('user_id, full_name')
            .inFilter('user_id', userIds);

        final profilesMap = <String, String>{
          for (var p in (profilesRes as List).map(toSafe))
            p['user_id'] as String: (p['full_name'] as String? ?? '')
        };

        return ordersList.map((order) {
          final uId = order['user_id'] as String;
          return <String, dynamic>{
            ...order,
            'profiles': profilesMap.containsKey(uId)
                ? {'full_name': profilesMap[uId]}
                : null,
          };
        }).toList();
      }
    }
  }


  void _reloadOrders() {
    setState(() {
      _ordersFuture = _loadOrders();
    });
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', int.parse(orderId)); // id es int8, comparar como entero

      _reloadOrders();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a "$newStatus"'),
          backgroundColor: AppColors.gold,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar estado: $e'),
          backgroundColor: AppColors.crimson,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _deleteOrder(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descartar Pedido'),
        content: const Text('¿Estás seguro que deseas descartar este pedido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.crimson,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client
          .from('orders')
          .delete()
          .eq('id', int.parse(orderId));

      _reloadOrders();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido descartado'),
          backgroundColor: AppColors.crimson,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al descartar pedido: $e'),
          backgroundColor: AppColors.crimson,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/${dt.year} $hour:$min';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _sheinUrlController.dispose();
    _categoryNameController.dispose();
    super.dispose();
  }

  void _submitProduct() async {
    if ((_productFormKey.currentState?.validate() ?? false) && _selectedCategory != null) {
      final double price = double.tryParse(_priceController.text) ?? 0.0;
      
      try {
        // Ejecutamos el insert directamente para capturar el error exacto
        await Supabase.instance.client.from('products').insert({
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': price,
          'image_url': _productImages.isNotEmpty ? _productImages.first : '',
          'images': _productImages,
          'shein_url': _sheinUrlController.text.trim(),
          'category': _selectedCategory!,
          'gender': _selectedGender!,
          'in_stock': _inStock,
          'is_preorder': _isPreorder,
        });

        if (!mounted) return;

        // Actualizamos el estado del bloc
        context.read<CatalogBloc>().add(FetchCatalogProducts());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto subido exitosamente'),
            backgroundColor: AppColors.gold,
            duration: Duration(seconds: 3),
          ),
        );

        _nameController.clear();
        _descriptionController.clear();
        _priceController.clear();
        _sheinUrlController.clear();
        setState(() {
          _productImages = [];
          _inStock = true;
          _isPreorder = false;
          _selectedCategory = null;
          _selectedGender = 'Mujer';
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir: $e'),
            backgroundColor: AppColors.crimson,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } else if (_selectedCategory == null || _selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona categoría y género'),
          backgroundColor: AppColors.crimson,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _submitCategory() {
    if (_categoryFormKey.currentState?.validate() ?? false) {
      final categoryName = _categoryNameController.text.trim();
      if (categoryName.toUpperCase() == 'NA') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El nombre de categoría "NA" está reservado.'),
            backgroundColor: AppColors.crimson,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      context.read<CategoryBloc>().add(AddCategory(categoryName));
      _categoryNameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Categoría añadida'),
          backgroundColor: AppColors.gold,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Panel de Administración', style: TextStyle(color: AppColors.white)),
          backgroundColor: AppColors.crimson,
          iconTheme: const IconThemeData(color: AppColors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          bottom: const TabBar(
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.white,
            indicatorColor: AppColors.gold,
            tabs: [
              Tab(icon: Icon(Icons.add_box), text: 'Añadir'),
              Tab(icon: Icon(Icons.edit), text: 'Editar'),
              Tab(icon: Icon(Icons.category), text: 'Categorías'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Ventas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildProductTab(),
            _buildEditListTab(),
            _buildCategoryTab(),
            _buildOrdersTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _productFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Añadir Nuevo Producto',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre del Producto'),
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 3,
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Precio (\$)', prefixText: '\$ '),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requerido';
                if (double.tryParse(v) == null) return 'Debe ser numérico';
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Dropdown de Categorías alimentado del Bloc
            BlocBuilder<CategoryBloc, CategoryState>(
              builder: (context, state) {
                if (state is CategoryLoading || state is CategoryInitial) {
                  return const CircularProgressIndicator();
                } else if (state is CategoryLoaded) {
                  final categories = state.categories;
                  // Nos aseguramos que _selectedCategory sea válido si no es null
                  if (_selectedCategory != null && !categories.any((c) => c.name == _selectedCategory)) {
                    _selectedCategory = null; // reset si se borró la categoría
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: categories.map((c) => DropdownMenuItem(
                      value: c.name,
                      child: Text(c.name),
                    )).toList(),
                    onChanged: (val) {
                      setState(() => _selectedCategory = val);
                    },
                  );
                } else {
                  return const Text('Error al cargar categorías');
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Dropdown de Género
            DropdownButtonFormField<String>(
              initialValue: _selectedGender,
              decoration: const InputDecoration(labelText: 'Departamento (Género)'),
              items: ['Mujer', 'Hombre', 'Unisex'].map((g) => DropdownMenuItem(
                value: g,
                child: Text(g),
              )).toList(),
              onChanged: (val) {
                setState(() => _selectedGender = val);
              },
              validator: (v) => v == null ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('¿Es bajo pedido? (15-20 días)'),
              subtitle: Text(_isPreorder ? 'Producto sujeto a importación.' : 'En físico (Entrega inmediata).'),
              value: _isPreorder,
              activeColor: AppColors.gold,
              onChanged: (val) {
                setState(() => _isPreorder = val);
              },
            ),
            const SizedBox(height: 16),
            
            _ImagesEditor(
              initialImages: _productImages,
              onChanged: (images) => setState(() => _productImages = images),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sheinUrlController,
              decoration: const InputDecoration(labelText: 'URL de Shein (Opcional)', hintText: 'https://...'),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('En Stock', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Disponible para comprar'),
              activeThumbColor: AppColors.crimson,
              value: _inStock,
              onChanged: (val) => setState(() => _inStock = val),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _submitProduct,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Subir Producto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.crimson,
                  foregroundColor: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditListTab() {
    return BlocBuilder<CatalogBloc, CatalogState>(
      builder: (context, state) {
        if (state is CatalogLoading || state is CatalogInitial) {
          return const Center(child: CircularProgressIndicator(color: AppColors.crimson));
        } else if (state is CatalogLoaded) {
          final products = state.allProducts;
          if (products.isEmpty) {
            return const Center(child: Text('No hay productos para editar.'));
          }
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: product.imageUrl.isNotEmpty
                    ? Image.network(product.imageUrl, width: 50, height: 50, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image))
                    : const Icon(Icons.image),
                title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('\$${product.price.toStringAsFixed(2)} - ${product.category}'),
                trailing: const Icon(Icons.edit, color: AppColors.crimson),
                onTap: () => _showEditDialog(product),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showEditDialog(Product product) {
    final editFormKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: product.name);
    final descCtrl = TextEditingController(text: product.description);
    final priceCtrl = TextEditingController(text: product.price.toString());
    List<String> editImages = product.images.isNotEmpty ? List.from(product.images) : [if (product.imageUrl.isNotEmpty) product.imageUrl];
    final sheinCtrl = TextEditingController(text: product.sheinUrl);
    String? selectedCategory = product.category;
    String? selectedGender = product.gender;
    bool inStock = product.inStock;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Editar Producto'),
          content: SingleChildScrollView(
            child: Form(
              key: editFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    maxLines: 3,
                    validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Precio'),
                    validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 10),
                  BlocBuilder<CategoryBloc, CategoryState>(
                    builder: (context, state) {
                      if (state is CategoryLoaded) {
                        return DropdownButtonFormField<String>(
                          initialValue: state.categories.any((c) => c.name == selectedCategory) ? selectedCategory : null,
                          decoration: const InputDecoration(labelText: 'Categoría'),
                          items: state.categories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                          onChanged: (val) => selectedCategory = val,
                        );
                      }
                      return const CircularProgressIndicator();
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedGender,
                    decoration: const InputDecoration(labelText: 'Género'),
                    items: ['Mujer', 'Hombre', 'Unisex'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (val) => selectedGender = val,
                  ),
                  const SizedBox(height: 16),
                  _ImagesEditor(
                    initialImages: editImages,
                    onChanged: (images) => editImages = images,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (editFormKey.currentState?.validate() ?? false) {
                  final updatedProduct = Product(
                    id: product.id,
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim().isEmpty ? product.description : descCtrl.text.trim(),
                    price: double.tryParse(priceCtrl.text) ?? product.price,
                    imageUrl: editImages.isNotEmpty ? editImages.first : '',
                    images: editImages,
                    sheinUrl: sheinCtrl.text.trim().isEmpty ? product.sheinUrl : sheinCtrl.text.trim(),
                    category: selectedCategory ?? product.category,
                    gender: selectedGender ?? product.gender,
                    inStock: inStock,
                  );
                  context.read<CatalogBloc>().add(UpdateCatalogProduct(updatedProduct));
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Producto actualizado'),
                      backgroundColor: AppColors.gold,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson, foregroundColor: Colors.white),
              child: const Text('Actualizar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryTab() {
    return Column(
      children: [
        // Formulario de Nueva Categoría
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _categoryFormKey,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _categoryNameController,
                    decoration: const InputDecoration(labelText: 'Nueva Categoría', hintText: 'Ej. Accesorios'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _submitCategory,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson, foregroundColor: AppColors.white),
                  child: const Text('Añadir'),
                ),
              ],
            ),
          ),
        ),
        const Divider(),
        // Lista de Categorías
        Expanded(
          child: BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, state) {
              if (state is CategoryLoading || state is CategoryInitial) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is CategoryError) {
                return Center(child: Text('Error: ${state.message}'));
              } else if (state is CategoryLoaded) {
                if (state.categories.isEmpty) {
                  return const Center(child: Text('No hay categorías'));
                }
                return ListView.builder(
                  itemCount: state.categories.length,
                  itemBuilder: (context, index) {
                    final category = state.categories[index];
                    return ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.crimson.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.label_outline, color: AppColors.crimson, size: 20),
                      ),
                      title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.crimson),
                        tooltip: 'Eliminar categoría',
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text('¿Eliminar categoría?'),
                              content: Text(
                                'Los productos en "${category.name}" serán movidos a la categoría general.\n\n¿Deseas continuar?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.crimson,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && context.mounted) {
                            try {
                              // 1. Update products to NA
                              await Supabase.instance.client
                                  .from('products')
                                  .update({'category': 'NA'})
                                  .eq('category', category.name);
                              
                              // 2. Delete category
                              await Supabase.instance.client
                                  .from('categories')
                                  .delete()
                                  .eq('id', category.id);
                              
                              if (context.mounted) {
                                context.read<CategoryBloc>().add(FetchCategories());
                                context.read<CatalogBloc>().add(FetchCatalogProducts());
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Categoría eliminada correctamente'),
                                    backgroundColor: AppColors.gold,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error al eliminar: $e'),
                                    backgroundColor: AppColors.crimson,
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.crimson));
        } else if (snapshot.hasError) {
          return Center(child: Text('Error al cargar pedidos: ${snapshot.error}', style: const TextStyle(color: AppColors.crimson)));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay ventas registradas.'));
        }

        final orders = snapshot.data!;

        return RefreshIndicator(
          color: AppColors.crimson,
          onRefresh: () async {
            _reloadOrders();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index]; // Already Map<String, dynamic> from _loadOrders
              final total = double.tryParse(order['total'].toString()) ?? 0.0;
              final date = order['created_at'] as String? ?? '';
              final status = order['status'] as String? ?? 'Pendiente';
              final rawProfile = order['profiles'];
              final profile = rawProfile != null
                  ? Map<String, dynamic>.from(rawProfile as Map)
                  : null;
              final customerName = profile?['full_name'] as String? ?? order['user_id'] as String? ?? 'Usuario';

              return Card(
                color: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.borderLight),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Pedido #${order['id'].toString().toUpperCase()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          // DropdownButton para estado
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: ['Pendiente', 'Procesando', 'Enviado', 'Entregado', 'Cancelado'].contains(status) ? status : 'Pendiente',
                              dropdownColor: AppColors.white,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.crimson,
                              ),
                              onChanged: (val) {
                                if (val != null && val != status) {
                                  _updateOrderStatus(order['id'].toString(), val);
                                }
                              },
                              items: ['Pendiente', 'Procesando', 'Enviado', 'Entregado', 'Cancelado'].map((opt) {
                                return DropdownMenuItem<String>(
                                  value: opt,
                                  child: Text(opt),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cliente: $customerName',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fecha: ${_formatDate(date)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showAdminOrderDetails(order),
                            icon: const Icon(Icons.receipt_long, size: 16),
                            label: const Text('Ver Artículos'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.crimson,
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '\$${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.crimson,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 22,
                                ),
                                tooltip: 'Descartar pedido',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _deleteOrder(order['id'].toString()),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showAdminOrderDetails(Map<String, dynamic> order) {
    final List<dynamic> items = order['items'] as List? ?? [];
    final total = double.tryParse(order['total'].toString()) ?? 0.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Artículos Comprados',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pedido #${order['id'].toString().toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = Map<String, dynamic>.from(items[index] as Map);
                        final price = double.tryParse(item['price'].toString()) ?? 0.0;
                        final qty = int.tryParse(item['quantity'].toString()) ?? 1;
                        final img = item['image_url'] as String? ?? '';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: img.isNotEmpty
                                    ? Image.network(
                                        img,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 56,
                                          height: 56,
                                          color: AppColors.surfaceLight,
                                          child: const Icon(Icons.image_not_supported, size: 20),
                                        ),
                                      )
                                    : Container(
                                        width: 56,
                                        height: 56,
                                        color: AppColors.surfaceLight,
                                        child: const Icon(Icons.image, size: 20),
                                      ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] ?? 'Producto',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$$price c/u  •  Cant: $qty',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\$${(price * qty).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.crimson,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total del Pedido',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.crimson,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ImagesEditor extends StatefulWidget {
  final List<String> initialImages;
  final ValueChanged<List<String>> onChanged;

  const _ImagesEditor({required this.initialImages, required this.onChanged});

  @override
  State<_ImagesEditor> createState() => _ImagesEditorState();
}

class _ImagesEditorState extends State<_ImagesEditor> {
  late List<String> _images;
  bool _uploading = false;
  final _urlCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.initialImages);
  }

  Future<void> _uploadImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(maxWidth: 800, imageQuality: 80);
    if (pickedFiles.isEmpty) return;

    setState(() => _uploading = true);

    try {
      List<String> newUrls = [];
      for (int i = 0; i < pickedFiles.length; i++) {
        final file = pickedFiles[i];
        final bytes = await file.readAsBytes();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg'; 

        await Supabase.instance.client.storage
            .from('products')
            .uploadBinary(fileName, bytes,
                fileOptions: const FileOptions(contentType: 'image/jpeg'));

        final publicUrl = Supabase.instance.client.storage
            .from('products')
            .getPublicUrl(fileName);
        newUrls.add(publicUrl);
      }

      setState(() {
        _images.addAll(newUrls);
      });
      widget.onChanged(_images);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir imágenes: $e'), backgroundColor: AppColors.crimson),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _addUrl() {
    final url = _urlCtrl.text.trim();
    if (url.isNotEmpty) {
      setState(() {
        _images.add(url);
        _urlCtrl.clear();
      });
      widget.onChanged(_images);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
    widget.onChanged(_images);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Imágenes del Producto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Pegar enlace de imagen',
                  hintText: 'https://...',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.crimson, size: 28),
              onPressed: _addUrl,
              tooltip: 'Añadir URL',
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_uploading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CircularProgressIndicator(color: AppColors.crimson, strokeWidth: 2),
          )
        else
          TextButton.icon(
            icon: const Icon(Icons.photo_library, color: AppColors.crimson),
            label: const Text('Subir desde Galería (Múltiple)', style: TextStyle(color: AppColors.crimson)),
            onPressed: _uploadImages,
          ),
        const SizedBox(height: 12),
        if (_images.isNotEmpty)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(_images.length, (index) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderLight),
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(_images[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.crimson,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
      ],
    );
  }
}
