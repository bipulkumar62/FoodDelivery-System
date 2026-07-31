import { Request, Response, NextFunction } from 'express';
import * as orderService from '../services/order.service';
import * as menuService from '../services/menu.service';
import { HTTP_STATUS } from '../constants';

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

export async function createMenuItem(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const item = await menuService.createMenuItem(req.body);
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
    const item = await menuService.updateMenuItem(req.params.id, req.body);
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
    await menuService.deleteMenuItem(req.params.id);
    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Menu item deleted successfully',
    });
  } catch (error) {
    next(error);
  }
}