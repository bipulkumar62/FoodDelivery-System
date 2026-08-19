import { TrackingService } from './tracking.service';
import { socketTrackingEvents } from './trackingEvents';
import * as orderRepo from '../repositories/order.repository';
import * as liveLocationRepo from '../repositories/liveLocation.repository';

/** Singleton used by HTTP controllers, socket handlers and order events. */
export const trackingService = new TrackingService(
  orderRepo,
  {
    upsert: liveLocationRepo.upsertLiveLocation,
    find: liveLocationRepo.findLiveLocationByOrderId,
    delete: liveLocationRepo.deleteLiveLocationByOrderId,
  },
  socketTrackingEvents,
);