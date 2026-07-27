import mongoose from 'mongoose';
import { Order, IOrder } from '../models/Order';
import { Menu, IMenuItem } from '../models/Menu';
import { AppError } from '../utils/AppError';
import { HTTP_STATUS } from '../constants';

export async function findMenuItemsByIds(
  ids: string[],
): Promise<IMenuItem[]> {
  const objectIds = ids.map((id) => {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw new AppError(`Invalid menu item ID: ${id}`, HTTP_STATUS.BAD_REQUEST);
    }
    return new mongoose.Types.ObjectId(id);
  });

  return Menu.find({ _id: { $in: objectIds } });
}

export async function findLastOrderId(): Promise<string | null> {
  const lastOrder = await Order.findOne({}, { orderId: 1, _id: 0 })
    .sort({ orderId: -1 })
    .lean();
  return lastOrder?.orderId ?? null;
}

export async function insertOrder(data: Partial<IOrder>): Promise<IOrder> {
  const order = await Order.create(data);
  return order;
}

export async function findOrderById(id: string): Promise<IOrder | null> {
  const query = mongoose.Types.ObjectId.isValid(id)
    ? { _id: id }
    : { orderId: id };
  return Order.findOne(query);
}

export async function findAllOrders(): Promise<IOrder[]> {
  return Order.find().sort({ createdAt: -1 });
}

export async function findOrdersByPhone(
  phone: string,
): Promise<IOrder[]> {
  return Order.find({ phone }).sort({ createdAt: -1 });
}

export async function findOrderAndUpdateStatus(
  id: string,
  status: string,
  completedAt?: Date,
): Promise<IOrder | null> {
  const query = mongoose.Types.ObjectId.isValid(id)
    ? { _id: id }
    : { orderId: id };
  const update: Record<string, unknown> = { orderStatus: status };
  if (completedAt) {
    update.completedAt = completedAt;
  }
  return Order.findOneAndUpdate(query, update, {
    new: true,
    runValidators: true,
  });
}


