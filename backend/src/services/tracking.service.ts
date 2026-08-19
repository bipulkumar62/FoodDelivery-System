import { AppError } from '../utils/AppError';
import { HTTP_STATUS } from '../constants';
import {
  canUpdateLocation,
  isTrackingAllowed,
  TrackingOrder,
} from '../utils/trackingPolicy';

export interface LiveLocationRecord {
  orderId: string;
  riderId: string;
  latitude: number;
  longitude: number;
  accuracy: number;
  updatedAt: Date;
}

export interface LiveLocationPayload {
  orderId: string;
  riderId: string;
  latitude: number;
  longitude: number;
  accuracy: number;
  timestamp: string;
}

export interface TrackingEventEmitter {
  emitLocation(orderId: string, payload: LiveLocationPayload): void;
  emitStopped(orderId: string, reason: string): void;
}

interface TrackingOrderRepo {
  findOrderById(id: string): Promise<TrackingOrder | null>;
}

interface LiveLocationRepo {
  upsert(data: Omit<LiveLocationRecord, 'updatedAt'>): Promise<LiveLocationRecord>;
  find(orderId: string): Promise<LiveLocationRecord | null>;
  delete(orderId: string): Promise<boolean>;
}

function toPayload(record: LiveLocationRecord): LiveLocationPayload {
  return {
    orderId: record.orderId,
    riderId: record.riderId,
    latitude: record.latitude,
    longitude: record.longitude,
    accuracy: record.accuracy,
    timestamp: record.updatedAt.toISOString(),
  };
}

function decisionError(
  reason: 'not_found' | 'not_out_for_delivery' | 'not_assigned',
): AppError {
  switch (reason) {
    case 'not_found':
      return new AppError('Order not found', HTTP_STATUS.NOT_FOUND);
    case 'not_out_for_delivery':
      return new AppError(
        'Order is not out for delivery. Tracking is not active.',
        HTTP_STATUS.CONFLICT,
      );
    case 'not_assigned':
      return new AppError(
        'Rider is not assigned to this order',
        HTTP_STATUS.FORBIDDEN,
      );
  }
}

/**
 * All tracking state transitions go through this class so that the exact
 * same authorisation and termination rules apply to every entry point
 * (rider start, rider location ping, rider stop, admin status change,
 * customer read).
 */
export class TrackingService {
  constructor(
    private readonly orderRepo: TrackingOrderRepo,
    private readonly liveRepo: LiveLocationRepo,
    private readonly emitter: TrackingEventEmitter,
  ) {}

  /** Rider taps "Start Delivery". Tracking begins only here and only if the
   * rider is authenticated, assigned, and the order is out for delivery. */
  async startTracking(
    orderId: string,
    riderId: string,
  ): Promise<{ orderId: string; tracking: boolean }> {
    const order = await this.orderRepo.findOrderById(orderId);
    const decision = canUpdateLocation(order, riderId);
    if (!decision.allowed) {
      throw decisionError(decision.reason);
    }
    return { orderId: order!.orderId ?? '', tracking: true };
  }

  /** Rider location ping (10-15 s / 25 m cadence enforced by rider app).
   * Re-validated on every ping: if the order is no longer out for delivery
   * the record is deleted and the customer is notified immediately. */
  async updateLocation(params: {
    orderId: string;
    riderId: string;
    latitude: number;
    longitude: number;
    accuracy: number;
  }): Promise<LiveLocationPayload> {
    const order = await this.orderRepo.findOrderById(params.orderId);
    const decision = canUpdateLocation(order, params.riderId);
    if (!decision.allowed) {
      if (decision.reason === 'not_out_for_delivery' && order) {
        // Server rejects the order as inactive: enforce the termination flow.
        await this.stopTracking(params.orderId, 'order_no_longer_active');
      }
      throw decisionError(decision.reason);
    }

    const record = await this.liveRepo.upsert({
      orderId: params.orderId,
      riderId: params.riderId,
      latitude: params.latitude,
      longitude: params.longitude,
      accuracy: params.accuracy,
    });

    const payload = toPayload(record);
    this.emitter.emitLocation(params.orderId, payload);
    return payload;
  }

  /** Single idempotent termination flow. Safe to call repeatedly. */
  async stopTracking(
    orderId: string,
    reason: string,
  ): Promise<{ orderId: string; active: boolean }> {
    await this.liveRepo.delete(orderId);
    this.emitter.emitStopped(orderId, reason);
    return { orderId, active: false };
  }

  /** Customer read path. Only the order's own phone can read it, and only
   * while the order is out for delivery. */
  async getLocationForCustomer(
    orderId: string,
    phone: string,
  ): Promise<{ active: boolean; location?: LiveLocationPayload }> {
    const order = await this.orderRepo.findOrderById(orderId);
    if (!order) {
      throw new AppError('Order not found', HTTP_STATUS.NOT_FOUND);
    }
    if (order.phone !== phone) {
      throw new AppError('Forbidden', HTTP_STATUS.FORBIDDEN);
    }
    if (!isTrackingAllowed(order.orderStatus)) {
      return { active: false };
    }
    const record = await this.liveRepo.find(orderId);
    if (!record) {
      return { active: false };
    }
    return { active: true, location: toPayload(record) };
  }
}