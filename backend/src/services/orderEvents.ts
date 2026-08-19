import { IOrder } from '../models/Order';
import { IOrderResponse } from '../interfaces/order.interface';
import { trackingService } from './tracking.instance';
import { orderRoom, ADMIN_ROOM } from './trackingEvents';

/**
 * Scoped order socket events.
 *
 * Privacy: order payloads (customer name/phone/address) and tracking events
 * are only published into the order's private room — never broadcast
 * globally. Rooms can only be joined after phone-number verification
 * (see server.ts), so one customer can never observe another order.
 */
export function emitNewOrder(order: IOrderResponse): void {
  if (global.io) {
    global.io.to(ADMIN_ROOM).emit('order:new', order);
  }
}

export function emitOrderStatusUpdate(order: IOrderResponse): void {
  if (global.io) {
    global.io.to(orderRoom(order._id)).emit('order:status-update', order);
    global.io.to(ADMIN_ROOM).emit('order:status-update', order);
  }
}

/**
 * Ran when an order reaches a terminal status (Delivered / Cancelled).
 * Runs the idempotent stopTracking() flow: deletes /live_locations/{orderId}
 * and notifies the customer room that tracking ended.
 */
export async function notifyOrderTerminal(order: IOrder): Promise<void> {
  await trackingService.stopTracking(order._id.toString(), 'order_terminal');
}