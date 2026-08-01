import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../network/api_client.dart';
import '../../network/api_exception.dart';
import '../../repositories/admin_menu_repository.dart';
import '../../widgets/menu_image_picker.dart';
import 'admin_login_screen.dart';

class AddMenuItemScreen extends StatefulWidget {
  const AddMenuItemScreen({super.key});

  @override
  State<AddMenuItemScreen> createState() => _AddMenuItemScreenState();
}

class _AddMenuItemScreenState extends State<AddMenuItemScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController(text: 'Biryani');
  final _imageController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _veg = false;
  bool _available = true;
  bool _isSaving = false;
  bool _isUploading = false;
  String? _formError;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _imageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _redirectToLogin() async {
    await adminLogout();
    ApiClient.instance.clearToken();
    pendingAdminRedirect = '/admin-menu/add';
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/admin-login');
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final category = _categoryController.text.trim();
    final image = _imageController.text.trim();

    String? error;
    if (name.isEmpty) {
      error = 'Item name is required';
    } else if (name.length > 100) {
      error = 'Item name must be at most 100 characters';
    } else if (price == null || price <= 0) {
      error = 'Price must be greater than zero';
    } else if (category.isEmpty) {
      error = 'Category is required';
    } else if (image.isNotEmpty) {
      final uri = Uri.tryParse(image);
      if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
        error = 'Image URL must be a valid HTTP or HTTPS URL';
      }
    }
    if (error != null) {
      setState(() => _formError = error);
      return;
    }

    setState(() {
      _isSaving = true;
      _formError = null;
    });
    try {
      await AdminMenuRepository().createMenuItem(
        name: name,
        price: price!,
        category: category,
        description: _descriptionController.text,
        image: image,
        veg: _veg,
        available: _available,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _redirectToLogin();
        return;
      }
      if (!mounted) return;
      setState(() => _formError = _extractBackendErrors(e));
    } catch (_) {
      if (!mounted) return;
      setState(() => _formError = 'Failed to add item. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _extractBackendErrors(ApiException e) {
    final data = e.data;
    if (data is Map) {
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors
            .map((x) => x is Map ? x['msg'].toString() : x.toString())
            .join('\n');
      }
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    return e.message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Menu Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                        prefixIcon: Icon(Icons.restaurant_menu),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        prefixText: '₹ ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _categoryController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    MenuImagePicker(
                      urlController: _imageController,
                      onUploadStarted: () =>
                          setState(() => _isUploading = true),
                      onUploadFinished: () =>
                          setState(() => _isUploading = false),
                      onUploaded: (_) => setState(() => _formError = null),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _imageController,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Image URL (optional)',
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: SwitchListTile(
                value: _veg,
                onChanged: (value) => setState(() => _veg = value),
                activeThumbColor: AppTheme.primaryColor,
                secondary: const Icon(
                  Icons.eco_outlined,
                  color: AppTheme.successColor,
                ),
                title: const Text(
                  'Vegetarian',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
            Card(
              child: SwitchListTile(
                value: _available,
                onChanged: (value) => setState(() => _available = value),
                activeThumbColor: AppTheme.primaryColor,
                secondary: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppTheme.primaryColor,
                ),
                title: const Text(
                  'Available for Ordering',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                subtitle: const Text('Show this item to customers'),
              ),
            ),
            if (_formError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formError!,
                  style:
                      const TextStyle(color: AppTheme.errorColor, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (_isSaving || _isUploading) ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }
}
