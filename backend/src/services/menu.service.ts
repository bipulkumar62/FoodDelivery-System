import { Menu, IMenuItem } from '../models/Menu';
import { AppError } from '../utils/AppError';
import { HTTP_STATUS } from '../constants';

export async function getAllMenuItems(): Promise<IMenuItem[]> {
  return Menu.find({ category: { $regex: /^biryani$/i }, available: true }).sort({ name: 1 });
}

export async function getMenuItemById(id: string): Promise<IMenuItem> {
  const item = await Menu.findById(id);
  if (!item) {
    throw new AppError('Menu item not found', HTTP_STATUS.NOT_FOUND);
  }
  return item;
}

export async function getCategories(): Promise<string[]> {
  const categories = await Menu.distinct('category', { available: true });
  return categories.map(
    (cat) => cat.charAt(0).toUpperCase() + cat.slice(1),
  );
}

// Admin functions
export async function createMenuItem(data: Partial<IMenuItem>): Promise<IMenuItem> {
  const item = await Menu.create(data);
  return item;
}

export async function updateMenuItem(id: string, data: Partial<IMenuItem>): Promise<IMenuItem> {
  const item = await Menu.findByIdAndUpdate(id, data, { new: true, runValidators: true });
  if (!item) {
    throw new AppError('Menu item not found', HTTP_STATUS.NOT_FOUND);
  }
  return item;
}

export async function updateMenuItemAvailability(id: string, available: boolean): Promise<IMenuItem> {
  const item = await Menu.findByIdAndUpdate(
    id,
    { available },
    { new: true, runValidators: true },
  );
  if (!item) {
    throw new AppError('Menu item not found', HTTP_STATUS.NOT_FOUND);
  }
  return item;
}

export async function deleteMenuItem(id: string): Promise<void> {
  const item = await Menu.findByIdAndDelete(id);
  if (!item) {
    throw new AppError('Menu item not found', HTTP_STATUS.NOT_FOUND);
  }
}
