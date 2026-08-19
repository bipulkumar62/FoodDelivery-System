import { test } from 'node:test';
import assert from 'node:assert/strict';
import { TrackingService, LiveLocationPayload } from '../services/tracking.service';

interface FakeOrder {
  _id: string;
  orderId: string;
  phone: string;
  orderStatus: string;
  riderId: string | null;
}

function makeOrder(overrides: Partial<FakeOrder> = {}): FakeOrder {
  return {
    _id: 'order-1',
    orderId: 'PB100001',
    phone: '9876543210',
    orderStatus: 'Out For Delivery',
    riderId: 'rider-1',
    ...overrides,
  };
}

function makeHarness(orders: FakeOrder[]) {
  const store = new Map<string, any>();
  const emittedLocation: Array<{ orderId: string; payload: LiveLocationPayload }> = [];
  const emittedStopped: Array<{ orderId: string; reason: string }> = [];
  let deleted = 0;

  const service = new TrackingService(
    {
      findOrderById: async (id: string) => {
        const found = orders.find((o) => o._id === id || o.orderId === id);
        return found ?? null;
      },
    },
    {
      upsert: async (data) => ({
        orderId: data.orderId,
        riderId: data.riderId,
        latitude: data.latitude,
        longitude: data.longitude,
        accuracy: data.accuracy,
        updatedAt: new Date('2026-08-19T10:00:00Z'),
      }),
      find: async (orderId: string) => store.get(orderId) ?? null,
      delete: async (orderId: string) => {
        const existed = store.has(orderId);
        store.delete(orderId);
        if (existed) deleted += 1;
        return existed;
      },
    },
    {
      emitLocation: (orderId, payload) =>
        emittedLocation.push({ orderId, payload }),
      emitStopped: (orderId, reason) => emittedStopped.push({ orderId, reason }),
    },
  );

  return { service, store, emittedLocation, emittedStopped, countDeletes: () => deleted };
}

test('startTracking rejected before out for delivery', async () => {
  const h = makeHarness([
    makeOrder({ orderStatus: 'Preparing', _id: 'o2' }),
  ]);
  await assert.rejects(
    h.service.startTracking('o2', 'rider-1'),
    /not out for delivery/i,
  );
});

test('startTracking rejected for unassigned rider', async () => {
  const h = makeHarness([makeOrder()]);
  await assert.rejects(
    h.service.startTracking('order-1', 'rider-999'),
    /not assigned/i,
  );
});

test('startTracking succeeds only for assigned rider on out-for-delivery order', async () => {
  const h = makeHarness([makeOrder()]);
  const result = await h.service.startTracking('order-1', 'rider-1');
  assert.deepEqual(result, { orderId: 'PB100001', tracking: true });
});

test('location update rejected after remote delivered status (record deleted, customer notified)', async () => {
  const orders = [makeOrder()];
  const h = makeHarness(orders);
  await h.service.startTracking('order-1', 'rider-1');
  h.store.set('order-1', { orderId: 'order-1' });

  // Server receives the delivered transition.
  orders[0].orderStatus = 'Delivered';

  await assert.rejects(
    h.service.updateLocation({
      orderId: 'order-1',
      riderId: 'rider-1',
      latitude: 26.2,
      longitude: 84.34,
      accuracy: 12,
    }),
    /not out for delivery/i,
  );
  assert.equal(h.countDeletes(), 1, 'live location must be deleted');
  assert.equal(h.emittedStopped.length, 1);
  assert.equal(h.emittedStopped[0].reason, 'order_no_longer_active');
});

test('location update rejected after remote cancelled status', async () => {
  const orders = [makeOrder()];
  const h = makeHarness(orders);
  h.store.set('order-1', { orderId: 'order-1' });
  orders[0].orderStatus = 'Cancelled';
  await assert.rejects(
    h.service.updateLocation({
      orderId: 'order-1',
      riderId: 'rider-1',
      latitude: 26.2,
      longitude: 84.34,
      accuracy: 12,
    }),
  );
  assert.equal(h.countDeletes(), 1);
});

test('stopTracking is idempotent and notifies exactly once', async () => {
  const h = makeHarness([makeOrder()]);
  h.store.set('order-1', { orderId: 'order-1' });

  await h.service.stopTracking('order-1', 'rider_ended');
  await h.service.stopTracking('order-1', 'rider_ended');
  await h.service.stopTracking('order-1', 'order_terminal');

  assert.equal(h.countDeletes(), 1, 'delete must happen only once');
  assert.equal(h.emittedStopped.length, 3);
  assert.equal(h.store.has('order-1'), false);
});

test('customer cannot read another order location (phone mismatch)', async () => {
  const h = makeHarness([makeOrder({ phone: '9876543210' })]);
  h.store.set('order-1', { orderId: 'order-1' });
  await assert.rejects(
    h.service.getLocationForCustomer('order-1', '1111111111'),
    /forbidden/i,
  );
});

test('customer read returns inactive when order is not out for delivery', async () => {
  const h = makeHarness([makeOrder({ orderStatus: 'Delivered' })]);
  h.store.set('order-1', { orderId: 'order-1' });
  const result = await h.service.getLocationForCustomer('order-1', '9876543210');
  assert.equal(result.active, false);
  assert.equal(result.location, undefined);
});

test('customer read returns active location only for own order while tracking', async () => {
  const h = makeHarness([makeOrder()]);
  h.store.set('order-1', {
    orderId: 'order-1',
    riderId: 'rider-1',
    latitude: 26.2,
    longitude: 84.34,
    accuracy: 8,
    updatedAt: new Date('2026-08-19T10:00:00Z'),
  });
  const result = await h.service.getLocationForCustomer('order-1', '9876543210');
  assert.equal(result.active, true);
  assert.equal(result.location!.latitude, 26.2);
  assert.equal(result.location!.riderId, 'rider-1');
});

test('duplicate start calls are safe', async () => {
  const h = makeHarness([makeOrder()]);
  const first = await h.service.startTracking('order-1', 'rider-1');
  const second = await h.service.startTracking('order-1', 'rider-1');
  assert.deepEqual(first, second);
});

test('tracking payload contains only the required fields', async () => {
  const h = makeHarness([makeOrder()]);
  const payload = await h.service.updateLocation({
    orderId: 'order-1',
    riderId: 'rider-1',
    latitude: 26.2,
    longitude: 84.34,
    accuracy: 15,
  });
  assert.deepEqual(Object.keys(payload).sort(), [
    'accuracy',
    'latitude',
    'longitude',
    'orderId',
    'riderId',
    'timestamp',
  ]);
});