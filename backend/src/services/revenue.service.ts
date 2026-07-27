import { IOrder } from '../models/Order';
import { Revenue, IRevenue } from '../models/Revenue';
import { AppError } from '../utils/AppError';
import { HTTP_STATUS } from '../constants';

export async function calculateTodaysRevenue(): Promise<IRevenue> {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  const deliveredOrders = await (await import('../models/Order')).Order.find({
    orderStatus: 'Delivered',
    createdAt: { $gte: today, $lt: tomorrow },
  }).select('_id total');

  const totalAmount = deliveredOrders.reduce((sum, order) => sum + (order.total || 0), 0);
  const orderIds = deliveredOrders.map(o => o._id);

  const revenue = await Revenue.findOneAndUpdate(
    { date: today },
    {
      $set: {
        totalAmount,
        deliveredOrderCount: deliveredOrders.length,
        orderIds,
      },
    },
    { upsert: true, new: true, runValidators: true },
  );

  return revenue;
}

export async function getTodaysRevenue(): Promise<IRevenue | null> {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return Revenue.findOne({ date: today });
}

export async function deleteTodaysRevenue(): Promise<void> {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  await Revenue.findOneAndDelete({ date: today });
  // Idempotent: no error if record doesn't exist
}

export async function getRevenueHistory(limit = 30): Promise<IRevenue[]> {
  return Revenue.find().sort({ date: -1 }).limit(limit);
}