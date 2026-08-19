import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/socket_service.dart';
import '../../services/audio_service.dart';
import '../../network/api_client.dart';
import '../../network/api_exception.dart';
import '../../network/network_constants.dart';
import '../../config/theme.dart';
import 'admin_login_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<dynamic> _orders = [];
  List<dynamic> _riders = [];
  final Map<String, String?> _selectedRider = {};
  bool _loading = true;
  String? _error;
  Timer? _timer;
  double _todayRevenue = 0;
  int _deliveredCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _fetchRiders();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchOrders());
    _initSocket();
  }

  void _initSocket() {
    AudioService().init();
    SocketService.instance.connect();
    // Authenticate this socket into the admin room: order events are no
    // longer broadcast to every connected client.
    getAdminToken().then((token) {
      if (token != null && token.isNotEmpty) {
        SocketService.instance.adminAuth(token);
      }
    });
    SocketService.instance.onNewOrder((data) {
      if (mounted) {
        AudioService().playBeep();
        _fetchOrders();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    SocketService.instance.disconnect();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    try {
      debugPrint(
        '[AdminOrders] GET ${NetworkConstants.baseUrl}/admin/orders | auth token present: '
        '${ApiClient.instance.hasAuthToken}',
      );
      final response = await ApiClient.instance.get('/admin/orders');
      if (!mounted) return;

      final List<dynamic> orders;
      try {
        orders = response is List
            ? response
            : (response['data'] as List<dynamic>? ?? []);
      } catch (e) {
        debugPrint('[AdminOrders] response parse failed: $e');
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Unexpected server response';
        });
        return;
      }

      // Calculate today's revenue from Delivered orders
      double revenue = 0;
      int deliveredCount = 0;
      for (final order in orders) {
        final status = (order['orderStatus'] as String?) ?? '';
        if (status == 'Delivered') {
          final total = (order['total'] as num?)?.toDouble() ?? 0.0;
          revenue += total;
          deliveredCount++;
        }
      }

      setState(() {
        _orders = orders;
        _loading = false;
        _error = null;
        _todayRevenue = revenue;
        _deliveredCount = deliveredCount;
      });
    } on ApiException catch (e) {
      debugPrint('[AdminOrders] request failed: status=${e.statusCode} message=${e.message}');
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _redirectToLogin();
        return;
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      debugPrint('[AdminOrders] unexpected error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _redirectToLogin() async {
    debugPrint('[AdminOrders] session invalid, redirecting to login');
    await adminLogout();
    ApiClient.instance.clearToken();
    pendingAdminRedirect = '/admin-orders';
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/admin-login');
  }

  Future<void> _fetchRiders() async {
    try {
      final response = await ApiClient.instance.get('/admin/riders');
      final List<dynamic> riders;
      try {
        riders = response is List
            ? response
            : (response['data'] as List<dynamic>? ?? []);
      } catch (e) {
        return;
      }
      if (!mounted) return;
      setState(() => _riders = riders);
    } catch (_) {
      // Riders are optional for the UI; retry next screen open.
    }
  }

  Future<void> _assignRider(String orderId, String? riderId) async {
    try {
      await ApiClient.instance.patch('/admin/orders/$orderId/rider', data: {
        'riderId': riderId,
      });
      _fetchOrders();
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _redirectToLogin();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {}
  }

  Future<void> _showAddRiderDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final passwordController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Rider'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: mobileController,
                decoration: const InputDecoration(labelText: 'Mobile (10 digits)'),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.trim().length != 10 ? 'Enter a valid 10-digit mobile' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) =>
                    v == null || v.trim().length < 6 ? 'Min 6 characters' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created != true || !mounted) return;
    try {
      await ApiClient.instance.post('/admin/riders', data: {
        'name': nameController.text.trim(),
        'mobile': mobileController.text.trim(),
        'password': passwordController.text,
      });
      await _fetchRiders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rider created. Share the credentials with the delivery partner.')),
        );
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _redirectToLogin();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {}
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await ApiClient.instance.patch('/orders/$id/status', data: {
        'status': status,
      });
      // Stop beep if order is accepted or cancelled
      if (status == 'Accepted' || status == 'Cancelled') {
        AudioService().stopBeep();
      }
      _fetchOrders();
    } on ApiException catch (e) {
      debugPrint('[AdminOrders] status update failed: status=${e.statusCode} message=${e.message}');
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _redirectToLogin();
      }
    } catch (_) {}
  }

  void _onLogout() async {
    await adminLogout();
    ApiClient.instance.clearToken();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/admin-login');
  }

  String _formatDateTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toUtc().add(const Duration(hours: 5, minutes: 30));
      // Format: 25 Jul 2026, 10:45 AM
      final day = dt.day.toString().padLeft(2, '0');
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = monthNames[dt.month - 1];
      final year = dt.year;
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$day $month $year, ${hour.toString().padLeft(2, '0')}:$minute $amPm';
    } catch (_) {
      return iso;
    }
  }

  String _formatRevenue(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  Widget _buildRevenueHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Revenue",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (_todayRevenue > 0)
                TextButton.icon(
                  onPressed: _fetchOrders,
                  icon: const Icon(Icons.refresh, size: 16, color: AppTheme.primaryColor),
                  label: const Text('Refresh', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatRevenue(_todayRevenue),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          if (_deliveredCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Delivered Orders: $_deliveredCount',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRiderRow(dynamic order) {
    final id = (order['_id'] as String?) ?? '';
    final current = (order['riderId'] as String?) ?? '';
    final selected = _selectedRider[id] ?? current;
    return Row(
      children: [
        const Text(
          'Rider: ',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: DropdownButton<dynamic>(
            value: selected.isEmpty ? '' : selected,
            isExpanded: true,
            hint: const Text('Unassigned'),
            items: [
              const DropdownMenuItem(value: '', child: Text('Unassigned')),
              ..._riders.map(
                (r) => DropdownMenuItem(
                  value: r['id'] as String,
                  child: Text(
                    '${r['name']} (${r['mobile']})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _selectedRider[id] = v as String?),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            final value = _selectedRider[id] ?? current;
            _assignRider(id, value.isEmpty ? null : value);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          child: const Text('Assign', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildStatusActions(dynamic order) {
    final status = (order['orderStatus'] as String?) ?? '';
    final id = (order['_id'] as String?) ?? '';

    // Order Received (Pending, Accepted, Preparing) -> can move to next stage or Cancel
    if (status == 'Pending') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus(id, 'Accepted'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Confirm', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus(id, 'Cancelled'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Cancel', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
        ],
      );
    }

    if (status == 'Accepted') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus(id, 'Preparing'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Start Preparing', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
        ],
      );
    }

    if (status == 'Preparing') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus(id, 'Out For Delivery'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Out for Delivery', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
        ],
      );
    }

    if (status == 'Out For Delivery') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus(id, 'Delivered'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Delivered', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
        ],
      );
    }

    // Delivered or Cancelled or Rejected - show badge only
    Color badgeColor;
    String badgeText;
    if (status == 'Delivered') {
      badgeColor = Colors.green;
      badgeText = 'Delivered';
    } else if (status == 'Cancelled' || status == 'Rejected') {
      badgeColor = Colors.red;
      badgeText = status;
    } else {
      badgeColor = Colors.grey;
      badgeText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(badgeText, style: TextStyle(color: badgeColor, fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            tooltip: 'Add Rider',
            onPressed: _showAddRiderDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _onLogout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Failed to load orders', style: TextStyle(color: AppTheme.errorColor)),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: _fetchOrders, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(0),
                    itemCount: _orders.isEmpty ? 2 : _orders.length + 1,
                    itemBuilder: (context, index) {
                      // First item is revenue header
                      if (index == 0) {
                        return _buildRevenueHeader();
                      }

                      // Empty state
                      if (_orders.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No orders yet'),
                          ),
                        );
                      }

                      final order = _orders[index - 1];
                      final items = (order['items'] as List<dynamic>?) ?? [];
                      final status = (order['orderStatus'] as String?) ?? '';

                      Color statusColor;
                      String statusLabel;
                      switch (status) {
                        case 'Pending':
                          statusColor = Colors.orange;
                          statusLabel = 'Order Received';
                          break;
                        case 'Accepted':
                          statusColor = Colors.blue;
                          statusLabel = 'Confirmed';
                          break;
                        case 'Preparing':
                          statusColor = Colors.deepOrange;
                          statusLabel = 'Preparing';
                          break;
                        case 'Out For Delivery':
                          statusColor = Colors.indigo;
                          statusLabel = 'Out for Delivery';
                          break;
                        case 'Delivered':
                          statusColor = Colors.green;
                          statusLabel = 'Delivered';
                          break;
                        case 'Cancelled':
                        case 'Rejected':
                          statusColor = Colors.red;
                          statusLabel = status;
                          break;
                        default:
                          statusColor = Colors.grey;
                          statusLabel = status;
                      }

                      return Card(
                        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    order['orderId'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              _infoRow(Icons.person_outline, order['customerName'] ?? ''),
                              _infoRow(Icons.phone_outlined, order['phone'] ?? ''),
                              _infoRow(Icons.location_on_outlined, order['address'] ?? ''),
                              _infoRow(Icons.payment_outlined, order['paymentMethod'] ?? ''),
                              _infoRow(Icons.access_time, _formatDateTime(order['createdAt'])),
                              if (order['landmark'] != null && (order['landmark'] as String).isNotEmpty)
                                _infoRow(Icons.flag_outlined, order['landmark']),
                              if (order['latitude'] != null && order['longitude'] != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _infoRow(Icons.gps_fixed, 'Lat: ${order['latitude']}, Lng: ${order['longitude']}'),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final lat = order['latitude'];
                                          final lng = order['longitude'];
                                          final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                                          }
                                        },
                                        icon: const Icon(Icons.map, size: 18),
                                        label: const Text('Track Customer'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                _infoRow(Icons.gps_off, 'Location unavailable'),
                              const Divider(height: 16),
                              const Text('Items:', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              ...items.map((item) => Padding(
                                    padding: const EdgeInsets.only(left: 8, top: 2),
                                    child: Text(
                                      '${item['quantity']}x ${item['name']} - Rs.${item['subtotal']}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  )),
                              const Divider(height: 16),
                              Row(
                                children: [
                                  const Text('Total: ', style: TextStyle(fontWeight: FontWeight.w600)),
                                  Text(
                                    'Rs.${order['total']}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              if (!['Delivered', 'Cancelled', 'Rejected'].contains(status)) ...[
                                const SizedBox(height: 12),
                                _buildStatusActions(order),
                                const SizedBox(height: 12),
                                _buildRiderRow(order),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }
}