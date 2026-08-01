import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../models/admin_menu_item.dart';
import '../../providers/admin_menu_provider.dart';
import '../../providers/menu_provider.dart';
import '../../network/api_client.dart';
import '../../network/api_exception.dart';
import '../../utils/helpers.dart';
import '../../widgets/empty_state.dart';
import 'admin_login_screen.dart';

class AdminMenuScreen extends ConsumerStatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  ConsumerState<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends ConsumerState<AdminMenuScreen> {
  final Set<String> _busyItemIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    ref.invalidate(adminMenuProvider);
  }

  void _invalidateMenu() {
    ref.invalidate(adminMenuProvider);
    ref.invalidate(menuProvider);
  }

  Future<void> _redirectToLogin() async {
    await adminLogout();
    ApiClient.instance.clearToken();
    pendingAdminRedirect = '/admin-menu';
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/admin-login');
  }

  Future<void> _toggleAvailability(AdminMenuItem item) async {
    if (_busyItemIds.contains(item.id) || item.isArchived) return;
    setState(() => _busyItemIds.add(item.id));
    try {
      await ref
          .read(adminMenuRepositoryProvider)
          .updateAvailability(item.id, !item.available);
      _invalidateMenu();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _redirectToLogin();
        return;
      }
      if (mounted) _showError('Could not update availability. ${e.message}');
    } catch (_) {
      if (mounted) _showError('Could not update availability. Please try again.');
    } finally {
      if (mounted) setState(() => _busyItemIds.remove(item.id));
    }
  }

  Future<void> _archiveItem(AdminMenuItem item) async {
    if (_busyItemIds.contains(item.id) || item.isArchived) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Archive Item'),
        content: const Text(
          'Archive this menu item? It will be removed from the customer menu, but existing orders will remain unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Archive',
              style: const TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyItemIds.add(item.id));
    try {
      await ref.read(adminMenuRepositoryProvider).archiveItem(item.id);
      _invalidateMenu();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _redirectToLogin();
        return;
      }
      if (mounted) _showError('Could not archive item. ${e.message}');
    } catch (_) {
      if (mounted) _showError('Could not archive item. Please try again.');
    } finally {
      if (mounted) setState(() => _busyItemIds.remove(item.id));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  Future<void> _onAddItem() async {
    final added = await Navigator.pushNamed(context, '/admin-menu/add');
    if (added == true && mounted) {
      _invalidateMenu();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item added successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _onEditItem(AdminMenuItem item) async {
    final updated = await Navigator.pushNamed(context, '/admin-menu/edit',
        arguments: item);
    if (updated == true && mounted) {
      _invalidateMenu();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item updated successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(adminMenuProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        actions: [
          IconButton(
            tooltip: 'Add Item',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _onAddItem,
          ),
        ],
      ),
      body: menuAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          if (error is ApiException && error.statusCode == 401) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _redirectToLogin();
            });
            return const Center(child: CircularProgressIndicator());
          }
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
                    'Could not load menu.\n$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _load,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.restaurant_menu,
              title: 'No menu items yet',
              subtitle: 'Tap the + button to add your first item',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(adminMenuProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return _MenuItemCard(
                  item: item,
                  isBusy: _busyItemIds.contains(item.id),
                  onToggleAvailability: () => _toggleAvailability(item),
                  onEdit: () => _onEditItem(item),
                  onArchive: () => _archiveItem(item),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final AdminMenuItem item;
  final bool isBusy;
  final VoidCallback onToggleAvailability;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  const _MenuItemCard({
    required this.item,
    required this.isBusy,
    required this.onToggleAvailability,
    required this.onEdit,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: item.image.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: item.image,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => Center(
                              child: Icon(
                                Icons.restaurant,
                                size: 28,
                                color:
                                    AppTheme.primaryColor.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.restaurant,
                            size: 28,
                            color: AppTheme.primaryColor.withValues(alpha: 0.5),
                          ),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _chip(
                            item.category,
                            color: AppTheme.primaryColor,
                          ),
                          _chip(
                            item.veg ? 'Veg' : 'Non-Veg',
                            color: item.veg
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFE53935),
                          ),
                          if (item.isSoldOut)
                            _chip('SOLD OUT', color: AppTheme.errorColor),
                          if (item.isArchived)
                            _chip('ARCHIVED', color: AppTheme.textSecondary),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatPrice(item.price),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isBusy)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  color: AppTheme.textSecondary,
                  onPressed: isBusy ? null : onEdit,
                ),
                Switch(
                  value: item.available,
                  onChanged: (item.isArchived || isBusy)
                      ? null
                      : (_) => onToggleAvailability(),
                  activeThumbColor: AppTheme.primaryColor,
                ),
                IconButton(
                  tooltip: 'Archive',
                  icon: const Icon(Icons.archive_outlined),
                  color: item.isArchived
                      ? AppTheme.textSecondary
                      : AppTheme.errorColor,
                  onPressed: (item.isArchived || isBusy)
                      ? null
                      : onArchive,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
