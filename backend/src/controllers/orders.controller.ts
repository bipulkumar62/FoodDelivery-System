import { Request, Response, NextFunction } from 'express';
import * as orderService from '../services/order.service';
import { emitNewOrder } from '../services/orderEvents';
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

    // Emit socket event for new order (admin room only, never globally)
    emitNewOrder(order);

    res.status(HTTP_STATUS.CREATED).json({
      success: true,
      message: 'Order placed successfully',
      data: order,
    });
  } catch (error) {
    next(error);
  }
}

export async function getDeliveryQuote(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const { latitude, longitude } = req.body;
    const quote = await orderService.buildDeliveryQuote(latitude, longitude);
    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: quote,
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

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Order status updated successfully',
      data: order,
    });
  } catch (error) {
    next(error);
  }
}

export async function assignRiderToOrder(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const riderId = req.body.riderId ?? null;
    const order = await orderService.assignRider(req.params.id, riderId);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: riderId ? 'Rider assigned successfully' : 'Rider unassigned successfully',
      data: order,
    });
  } catch (error) {
    next(error);
  }
}
