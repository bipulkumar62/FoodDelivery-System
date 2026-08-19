import { OrderStatus } from '../types';

export interface TrackingOrder {
  orderId?: string;
  phone?: string;
  riderId?: string | null;
  orderStatus: string;
}

export type TrackingDecision =
  | { allowed: true }
  | { allowed: false; reason: 'not_found' | 'not_out_for_delivery' | 'not_assigned' };

/**
 * Tracking may only happen while the order is out for delivery.
 * No location collection, transmission or display in any other status.
 */
export function isTrackingAllowed(status: string): boolean {
  return status === OrderStatus.OutForDelivery;
}

/** The authenticated rider must be the one assigned to the order. */
export function isRiderAssigned(order: TrackingOrder, riderId: string): boolean {
  return Boolean(order.riderId) && order.riderId === riderId;
}

export function canUpdateLocation(
  order: TrackingOrder | null | undefined,
  riderId: string,
): TrackingDecision {
  if (!order) {
    return { allowed: false, reason: 'not_found' };
  }
  if (!isTrackingAllowed(order.orderStatus)) {
    return { allowed: false, reason: 'not_out_for_delivery' };
  }
  if (!isRiderAssigned(order, riderId)) {
    return { allowed: false, reason: 'not_assigned' };
  }
  return { allowed: true };
}

/** Terminal statuses stop tracking for good. */
export function isTerminalOrderStatus(status: string): boolean {
  return (
    status === OrderStatus.Delivered ||
    status === OrderStatus.Cancelled ||
    status === OrderStatus.Rejected
  );
}

/** A live-location record older than maxAgeMs is treated as unavailable. */
export function isLocationStale(
  updatedAt: Date | string | number | null | undefined,
  maxAgeMs: number,
  now: Date = new Date(),
): boolean {
  if (updatedAt == null) {
    return true;
  }
  const time = new Date(updatedAt).getTime();
  if (Number.isNaN(time)) {
    return true;
  }
  return now.getTime() - time > maxAgeMs;
}

export const CUSTOMER_STALE_LOCATION_MS = 45_000;
export const RIDER_PING_INTERVAL_MS = 10_000;
export const RIDER_PING_MAX_INTERVAL_MS = 15_000;
export const RIDER_DISTANCE_THRESHOLD_M = 25;