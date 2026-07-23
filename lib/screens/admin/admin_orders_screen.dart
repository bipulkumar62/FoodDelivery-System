import 'dart:async';
import 'package:flutter/material.dart';
import '../../network/api_client.dart';
import '../../config/theme.dart';
import 'admin_login_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchOrders());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    try {
      final json = await ApiClient.instance.get('/orders');
      if (!mounted) return;
      setState(() {
        _orders = (json['data'] as List<dynamic>?) ?? [];
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await ApiClient.instance.patch('/orders/$id/status', data: {
        'status': status,
      });
      _fetchOrders();
    } catch (_) {}
  }

  void _onLogout() async {
    await adminLogout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/admin-login');
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Widget _buildStatusActions(dynamic order) {
    final status = (order['orderStatus'] as String?) ?? '';
    final id = (order['_id'] as String?) ?? '';

    if (status == 'Pending') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus(id, 'Out for Delivery'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Out for Delivery', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
        ],
      );
    }
    if (status == 'Out for Delivery') {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text('Delivered', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Orders'),
        actions: [
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
              : _orders.isEmpty
                  ? const Center(child: Text('No orders yet'))
                  : RefreshIndicator(
                      onRefresh: _fetchOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          final items = (order['items'] as List<dynamic>?) ?? [];
                          final status = (order['orderStatus'] as String?) ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
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
                                          color: status == 'Pending'
                                              ? Colors.orange.withValues(alpha: 0.1)
                                              : status == 'Out for Delivery'
                                                  ? Colors.blue.withValues(alpha: 0.1)
                                                  : Colors.green.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: status == 'Pending'
                                                ? Colors.orange
                                                : status == 'Out for Delivery'
                                                    ? Colors.blue
                                                    : Colors.green,
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
                                  _infoRow(Icons.access_time, _formatTime(order['createdAt'])),
                                  if (order['landmark'] != null && (order['landmark'] as String).isNotEmpty)
                                    _infoRow(Icons.flag_outlined, order['landmark']),
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
                                  if (status != 'Delivered') ...[
                                    const SizedBox(height: 12),
                                    _buildStatusActions(order),
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