import { LiveLocationPayload, TrackingEventEmitter } from './tracking.service';

export function orderRoom(orderId: string): string {
  return `order:${orderId}`;
}

export const ADMIN_ROOM = 'admin';

/**
 * Real socket wiring (production). All tracking events are published only
 * into the order's private room; nothing location-related is ever broadcast
 * globally. Rooms are joined with phone-number verification in server.ts.
 */
export const socketTrackingEvents: TrackingEventEmitter = {
  emitLocation(orderId: string, payload: LiveLocationPayload): void {
    if (global.io) {
      global.io.to(orderRoom(orderId)).emit('tracking:location', payload);
    }
  },
  emitStopped(orderId: string, reason: string): void {
    if (global.io) {
      global.io
        .to(orderRoom(orderId))
        .emit('tracking:stopped', { orderId, reason });
    }
  },
};