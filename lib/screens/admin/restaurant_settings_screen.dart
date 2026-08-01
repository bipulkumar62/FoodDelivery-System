import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../network/api_client.dart';
import '../../network/api_exception.dart';
import 'admin_login_screen.dart';

class RestaurantSettingsScreen extends StatefulWidget {
  const RestaurantSettingsScreen({super.key});

  @override
  State<RestaurantSettingsScreen> createState() =>
      _RestaurantSettingsScreenState();
}

class _RestaurantSettingsScreenState extends State<RestaurantSettingsScreen> {
  final _nameController = TextEditingController();
  final _rateController = TextEditingController();

  bool _acceptingOrders = true;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  String? _formError;

  String _loadedName = '';
  double _loadedRate = 0;
  bool _loadedAcceptingOrders = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final response = await ApiClient.instance.get('/admin/settings');
      final data = response['data'] as Map<String, dynamic>;
      _loadedName = (data['restaurantName'] as String).trim();
      _loadedRate = (data['deliveryRatePerKm'] as num).toDouble();
      _loadedAcceptingOrders = data['acceptingOrders'] as bool;
      _nameController.text = _loadedName;
      _rateController.text = _formatRate(_loadedRate);
      _acceptingOrders = _loadedAcceptingOrders;
      if (!mounted) return;
      setState(() => _isLoading = false);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _redirectToLogin();
        return;
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _redirectToLogin() async {
    await adminLogout();
    ApiClient.instance.clearToken();
    pendingAdminRedirect = '/restaurant-settings';
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/admin-login');
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final rate = double.tryParse(_rateController.text.trim());

    String? error;
    if (name.isEmpty) {
      error = 'Restaurant name is required';
    } else if (name.length > 100) {
      error = 'Restaurant name must be at most 100 characters';
    } else if (rate == null || rate <= 0) {
      error = 'Delivery rate must be greater than zero';
    }
    if (error != null) {
      setState(() => _formError = error);
      return;
    }

    final payload = <String, dynamic>{};
    if (name != _loadedName) {
      payload['restaurantName'] = name;
    }
    if (rate != _loadedRate) {
      payload['deliveryRatePerKm'] = rate;
    }
    if (_acceptingOrders != _loadedAcceptingOrders) {
      payload['acceptingOrders'] = _acceptingOrders;
    }

    if (payload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes to save')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _formError = null;
    });
    try {
      final response =
          await ApiClient.instance.patch('/admin/settings', data: payload);
      final data = response['data'] as Map<String, dynamic>;
      _loadedName = (data['restaurantName'] as String).trim();
      _loadedRate = (data['deliveryRatePerKm'] as num).toDouble();
      _loadedAcceptingOrders = data['acceptingOrders'] as bool;
      if (!mounted) return;
      setState(() {
        _nameController.text = _loadedName;
        _rateController.text = _formatRate(_loadedRate);
        _acceptingOrders = _loadedAcceptingOrders;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurant settings saved successfully')),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _redirectToLogin();
        return;
      }
      if (!mounted) return;
      setState(() => _formError = _extractBackendErrors(e));
    } catch (_) {
      if (!mounted) return;
      setState(() => _formError = 'Failed to save settings. Please try again.');
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

  String _formatRate(double value) =>
      value == value.truncateToDouble()
          ? value.toInt().toString()
          : value.toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurant Settings')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppTheme.errorColor.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 12),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Restaurant Name',
                  prefixIcon: Icon(Icons.storefront_outlined),
                  counterText: '',
                ),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _rateController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Delivery Rate Per KM',
                  prefixText: '₹ ',
                ),
              ),
            ),
          ),
          Card(
            child: SwitchListTile(
              value: _acceptingOrders,
              onChanged: (value) => setState(() => _acceptingOrders = value),
              activeThumbColor: AppTheme.primaryColor,
              secondary: const Icon(
                Icons.delivery_dining_outlined,
                color: AppTheme.primaryColor,
              ),
              title: const Text(
                'Accepting Orders',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              subtitle: const Text('Allow customers to place new orders'),
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
                style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
