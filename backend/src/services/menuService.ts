import { Menu, IMenuItem } from '../models/Menu';
import { AppError } from '../utils/AppError';
import { HTTP_STATUS } from '../constants';

export async function getAllMenuItems(): Promise<IMenuItem[]> {
  return Menu.find({ available: true }).sort({ category: 1, name: 1 });
}

export async function getMenuItemsByCategory(category: string): Promise<IMenuItem[]> {
  return Menu.find({ category: category.toLowerCase(), available: true }).sort({ name: 1 });
}

export async function getMenuItemById(id: string): Promise<IMenuItem> {
  const item = await Menu.findById(id);
  if (!item) {
    throw new AppError('Menu item not found', HTTP_STATUS.NOT_FOUND);
  }
  return item;
}

export async function validateMenuItems(items: Array<{ itemId: string; quantity: number }>): Promise<Array<{ itemId: string; name: string; price: number; quantity: number }>> {
  if (!items || items.length === 0) {
    throw new AppError('At least one item is required', HTTP_STATUS.BAD_REQUEST);
  }

  const validatedItems: Array<{ itemId: string; name: string; price: number; quantity: number }> = [];

  for (const item of items) {
    if (!item.quantity || item.quantity < 1) {
      throw new AppError(`Invalid quantity for item ${item.itemId}`, HTTP_STATUS.BAD_REQUEST);
    }

    const menuItem = await Menu.findById(item.itemId);
    if (!menuItem) {
      throw new AppError(`Menu item ${item.itemId} not found`, HTTP_STATUS.NOT_FOUND);
    }
    if (!menuItem.available) {
      throw new AppError(`${menuItem.name} is not available`, HTTP_STATUS.BAD_REQUEST);
    }

    validatedItems.push({
      itemId: menuItem._id.toString(),
      name: menuItem.name,
      price: menuItem.price,
      quantity: item.quantity,
    });
  }

  return validatedItems;
}
