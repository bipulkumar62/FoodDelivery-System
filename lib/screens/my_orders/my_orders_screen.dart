import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/socket_service.dart';
import '../../providers/order_provider.dart';
import '../../widgets/order_status_chip.dart';
import '../../widgets/empty_state.dart';
import '../../config/theme.dart';
import '../../utils/helpers.dart';

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phoneAsync = ref.watch(cachedPhoneProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: phoneAsync.when(
        data: (phone) {
          if (phone == null || phone.isEmpty) {
            return const EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No previous orders.',
            );
          }
          return _OrdersBody();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const EmptyState(
          icon: Icons.inbox_outlined,
          title: 'No previous orders.',
        ),
      ),
    );
  }
}

class _OrdersBody extends ConsumerStatefulWidget {
  const _OrdersBody();

  @override
  ConsumerState<_OrdersBody> createState() => _OrdersBodyState();
}

class _OrdersBodyState extends ConsumerState<_OrdersBody> {
  final SocketService _socketService = SocketService.instance;

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  @override
  void dispose() {
    _socketService.offOrderStatusUpdate();
    super.dispose();
  }

  void _initSocket() {
    _socketService.connect();
    _socketService.onOrderStatusUpdate((data) {
      if (mounted) {
        ref.invalidate(ordersByPhoneProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersByPhoneProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ordersByPhoneProvider);
        await ref.read(ordersByPhoneProvider.future);
      },
      child: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'No Orders Yet',
                  subtitle: 'Order something delicious!',
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderCard(order: order);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
          children: [
            const SizedBox(height: 120),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 80, color: AppTheme.errorColor),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load orders',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.toString(),
                      style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(ordersByPhoneProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final dynamic order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                OrderStatusChip(status: order.orderStatus),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(order.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            if (order.estimatedDeliveryTime != null) ...[
              const SizedBox(height: 2),
              Text(
                'Est: ${_formatTime(order.estimatedDeliveryTime!)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            const Divider(height: 24),
            ...order.items.asMap().entries.map((e) => _buildItemRow(e.value, e.key == order.items.length - 1)),
            const Divider(height: 20),
            _buildBillRow('Subtotal', formatPrice(order.subtotal)),
            const SizedBox(height: 4),
            _buildBillRow('Delivery', formatPrice(order.deliveryCharge)),
            const Divider(height: 12),
            _buildBillRow('TOTAL', formatPrice(order.total), isBold: true, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(dynamic item, bool isLast) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 44,
              height: 44,
              child: item.image.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.image,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => _itemPlaceholder(item.name),
                    )
                  : _itemPlaceholder(item.name),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '₹${item.price.toStringAsFixed(0)} x ${item.quantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatPrice(item.subtotal),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemPlaceholder(String name) {
    return Container(
      color: AppTheme.primaryColor.withOpacity(0.1),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isBold = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 13,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppTheme.primaryColor : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  DateTime _toIst(DateTime dt) => dt.toUtc().add(const Duration(hours: 5, minutes: 30));

  String _formatDate(DateTime dt) {
    final ist = _toIst(dt);
    final day = ist.day.toString().padLeft(2, '0');
    final month = ist.month.toString().padLeft(2, '0');
    final hour = ist.hour.toString().padLeft(2, '0');
    final minute = ist.minute.toString().padLeft(2, '0');
    return '$day/$month/${ist.year} $hour:$minute';
  }

  String _formatTime(DateTime dt) {
    final ist = _toIst(dt);
    final hour = ist.hour.toString().padLeft(2, '0');
    final minute = ist.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
