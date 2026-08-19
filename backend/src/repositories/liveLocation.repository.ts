import { LiveLocation, ILiveLocation } from '../models/LiveLocation';

export interface LiveLocationUpsert {
  orderId: string;
  riderId: string;
  latitude: number;
  longitude: number;
  accuracy: number;
}

export async function upsertLiveLocation(
  data: LiveLocationUpsert,
): Promise<ILiveLocation> {
  return LiveLocation.findOneAndUpdate(
    { orderId: data.orderId },
    { $set: data },
    { new: true, upsert: true, runValidators: true },
  );
}

export async function findLiveLocationByOrderId(
  orderId: string,
): Promise<ILiveLocation | null> {
  return LiveLocation.findOne({ orderId });
}

export async function deleteLiveLocationByOrderId(
  orderId: string,
): Promise<boolean> {
  const result = await LiveLocation.deleteOne({ orderId });
  return result.deletedCount > 0;
}