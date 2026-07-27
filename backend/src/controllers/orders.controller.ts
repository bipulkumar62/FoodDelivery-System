import { Request, Response, NextFunction } from 'express';
import * as orderService from '../services/order.service';
import { HTTP_STATUS } from '../constants';

export async function createOrder(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const { customerName, phone, address, landmark, notes, items, latitude, longitude } = req.body;
    console.log('[createOrder] req.body.latitude:', latitude, 'req.body.longitude:', longitude);
    const order = await orderService.placeOrder({
      customerName,
      phone,
      address,
      landmark,
      notes,
      items,
      latitude,
      longitude,
    });

    // Emit socket event for new order
    if (global.io) {
      global.io.emit('order:new', order);
    }

    res.status(HTTP_STATUS.CREATED).json({
      success: true,
      message: 'Order placed successfully',
      data: order,
    });
  } catch (error) {
    next(error);
  }
}

export async function getOrderById(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const order = await orderService.getOrderById(req.params.id);
    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: order,
    });
  } catch (error) {
    next(error);
  }
}

export async function getOrdersByPhone(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const orders = await orderService.getOrdersByPhone(req.params.phone);
    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: orders,
    });
  } catch (error) {
    next(error);
  }
}

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

    // Emit socket event for status update
    if (global.io) {
      global.io.emit('order:status-update', order);
    }

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Order status updated successfully',
      data: order,
    });
  } catch (error) {
    next(error);
  }
}
