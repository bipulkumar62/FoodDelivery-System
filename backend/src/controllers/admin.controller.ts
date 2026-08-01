import { Request, Response, NextFunction } from 'express';
import * as orderService from '../services/order.service';
import * as menuService from '../services/menu.service';
import { AppError } from '../utils/AppError';
import { HTTP_STATUS } from '../constants';

const ALLOWED_MENU_UPDATE_FIELDS = [
  'name',
  'description',
  'price',
  'image',
  'category',
  'veg',
  'available',
  'isActive',
];

export async function getAllOrders(
  _req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const orders = await orderService.getAllOrders();
    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: orders,
    });
  } catch (error) {
    next(error);
  }
}

export async function updateOrderStatus(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const order = await orderService.updateOrderStatus(
      req.params.id,
      req.body.status,
    );

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Order status updated successfully',
      data: order,
    });
  } catch (error) {
    next(error);
  }
}

export async function getAllMenuAdmin(
  _req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const items = await menuService.getAllMenuItemsAdmin();
    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Menu fetched successfully',
      count: items.length,
      data: items,
    });
  } catch (error) {
    next(error);
  }
}

export async function createMenuItem(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const item = await menuService.createMenuItem(req.body);
    global.io?.emit('menu:created', { item });
    res.status(HTTP_STATUS.CREATED).json({
      success: true,
      message: 'Menu item created successfully',
      data: item,
    });
  } catch (error) {
    next(error);
  }
}

export async function updateMenuItem(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const unknownFields = Object.keys(req.body).filter(
      (key) => !ALLOWED_MENU_UPDATE_FIELDS.includes(key),
    );
    if (unknownFields.length > 0) {
      throw new AppError(
        `Unknown fields not allowed: ${unknownFields.join(', ')}`,
        HTTP_STATUS.BAD_REQUEST,
      );
    }
    if (Object.keys(req.body).length === 0) {
      throw new AppError(
        'At least one menu field is required',
        HTTP_STATUS.BAD_REQUEST,
      );
    }
    const item = await menuService.updateMenuItem(req.params.id, req.body);
    global.io?.emit('menu:updated', { item });
    if (typeof req.body.available === 'boolean') {
      global.io?.emit('menu:availability-updated', { item });
    }
    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Menu item updated successfully',
      data: item,
    });
  } catch (error) {
    next(error);
  }
}

export async function updateMenuItemAvailability(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const item = await menuService.updateMenuItemAvailability(
      req.params.id,
      req.body.available,
    );
    global.io?.emit('menu:availability-updated', { item });
    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Menu item availability updated successfully',
      data: item,
    });
  } catch (error) {
    next(error);
  }
}

export async function deleteMenuItem(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const item = await menuService.deleteMenuItem(req.params.id);
    global.io?.emit('menu:deleted', { menuItemId: item._id.toString() });
    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Menu item archived successfully',
      data: item,
    });
  } catch (error) {
    next(error);
  }
}