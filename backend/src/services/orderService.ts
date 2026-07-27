import mongoose from 'mongoose';
import { Order, IOrder } from '../models/Order';
import { OrderStatus, PaymentMethod } from '../types';
import { AppError } from '../utils/AppError';
import { HTTP_STATUS } from '../constants';

export interface CreateOrderInput {
  customerName: string;
  mobile: string;
  address: string;
  landmark?: string;
  latitude?: number;
  longitude?: number;
  items: Array<{
    itemId: string;
    name: string;
    price: number;
    quantity: number;
  }>;
  subtotal: number;
  deliveryCharge: number;
  grandTotal: number;
  paymentMethod: string;
}

const VALID_STATUSES = Object.values(OrderStatus) as string[];

export async function createOrder(input: CreateOrderInput): Promise<IOrder> {
  if (input.paymentMethod !== PaymentMethod.CashOnDelivery) {
    throw new AppError('Only Cash on Delivery is supported', HTTP_STATUS.BAD_REQUEST);
  }

  const order = await Order.create({
    customerName: input.customerName,
    mobile: input.mobile,
    address: input.address,
    landmark: input.landmark,
    latitude: input.latitude,
    longitude: input.longitude,
    items: input.items,
    subtotal: input.subtotal,
    deliveryCharge: input.deliveryCharge,
    grandTotal: input.grandTotal,
    paymentMethod: input.paymentMethod,
    status: OrderStatus.Pending,
  });

  console.log(`Order Created: ${order._id} by ${order.customerName}`);
  return order;
}

export async function getAllOrders(): Promise<IOrder[]> {
  return Order.find({ isDeleted: false }).sort({ createdAt: -1 });
}

export async function getOrderById(id: string): Promise<IOrder> {
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw new AppError('Invalid order ID', HTTP_STATUS.BAD_REQUEST);
  }

  const order = await Order.findOne({ _id: id, isDeleted: false });
  if (!order) {
    throw new AppError('Order not found', HTTP_STATUS.NOT_FOUND);
  }
  return order;
}

export async function updateOrderStatus(id: string, status: string): Promise<IOrder> {
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw new AppError('Invalid order ID', HTTP_STATUS.BAD_REQUEST);
  }

  if (!VALID_STATUSES.includes(status)) {
    throw new AppError(
      `Invalid status. Allowed: ${VALID_STATUSES.join(', ')}`,
      HTTP_STATUS.BAD_REQUEST,
    );
  }

  const order = await Order.findOneAndUpdate(
    { _id: id, isDeleted: false },
    { status },
    { new: true, runValidators: true },
  );

  if (!order) {
    throw new AppError('Order not found', HTTP_STATUS.NOT_FOUND);
  }

  console.log(`Status Changed: Order ${id} -> ${status}`);
  return order;
}

export async function softDeleteOrder(id: string): Promise<void> {
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw new AppError('Invalid order ID', HTTP_STATUS.BAD_REQUEST);
  }

  const order = await Order.findOneAndUpdate(
    { _id: id, isDeleted: false },
    { isDeleted: true },
    { new: true },
  );

  if (!order) {
    throw new AppError('Order not found', HTTP_STATUS.NOT_FOUND);
  }

  console.log(`Order Deleted (soft): ${id}`);
}
