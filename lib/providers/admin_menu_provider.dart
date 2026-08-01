import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_menu_item.dart';
import '../repositories/admin_menu_repository.dart';

final adminMenuRepositoryProvider =
    Provider<AdminMenuRepository>((ref) => AdminMenuRepository());

final adminMenuProvider = FutureProvider<List<AdminMenuItem>>((ref) async {
  return ref.read(adminMenuRepositoryProvider).getMenuItems();
});
