import mongoose, { Schema, Document } from 'mongoose';

/**
 * Latest live location for an active order.
 *
 * Privacy contract:
 * - Exactly one document per order (`orderId` unique) — never a history.
 * - The document is deleted when tracking stops (delivered / cancelled /
 *   unassigned / rider ends delivery) by `stopTracking`.
 * - A TTL index on `updatedAt` acts as a failsafe: even if the rider's phone
 *   loses internet or crashes and can never call stop, the record is
 *   automatically deleted after it goes stale.
 */
export interface ILiveLocation extends Document {
  orderId: string;
  riderId: string;
  latitude: number;
  longitude: number;
  accuracy: number;
  updatedAt: Date;
}

const liveLocationSchema = new Schema<ILiveLocation>(
  {
    orderId: {
      type: String,
      required: [true, 'Order ID is required'],
      unique: true,
      index: true,
    },
    riderId: {
      type: String,
      required: [true, 'Rider ID is required'],
    },
    latitude: {
      type: Number,
      required: [true, 'Latitude is required'],
      min: -90,
      max: 90,
    },
    longitude: {
      type: Number,
      required: [true, 'Longitude is required'],
      min: -180,
      max: 180,
    },
    accuracy: {
      type: Number,
      required: [true, 'Accuracy is required'],
      min: 0,
    },
  },
  {
    timestamps: true,
  },
);

// Failsafe TTL: stale live-location records are deleted automatically
// even if the rider device never calls stopTracking(). Live deliveries are
// short-lived, so a 30-minute window is more than enough; active orders keep
// refreshing `updatedAt` on every location ping (MongoDB TTL only expires
// documents older than this window, so an actively-updating record survives).
liveLocationSchema.index(
  { updatedAt: 1 },
  { expireAfterSeconds: 1800 },
);

export const LiveLocation = mongoose.model<ILiveLocation>(
  'LiveLocation',
  liveLocationSchema,
);

export const LIVE_LOCATION_TTL_SECONDS = 1800;