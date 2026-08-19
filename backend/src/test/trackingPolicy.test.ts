import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  canUpdateLocation,
  isLocationStale,
  isRiderAssigned,
  isTerminalOrderStatus,
  isTrackingAllowed,
} from '../utils/trackingPolicy';
import { LiveLocation } from '../models/LiveLocation';
import { Order } from '../models/Order';

test('trackingPolicy: no tracking before out for delivery', () => {
  assert.equal(isTrackingAllowed('Pending'), false);
  assert.equal(isTrackingAllowed('Accepted'), false);
  assert.equal(isTrackingAllowed('Preparing'), false);
  assert.equal(isTrackingAllowed('Out For Delivery'), true);
});

test('trackingPolicy: no tracking after delivered or cancelled', () => {
  assert.equal(isTrackingAllowed('Delivered'), false);
  assert.equal(isTrackingAllowed('Cancelled'), false);
  assert.equal(isTrackingAllowed('Rejected'), false);
  assert.equal(isTerminalOrderStatus('Delivered'), true);
  assert.equal(isTerminalOrderStatus('Cancelled'), true);
  assert.equal(isTerminalOrderStatus('Out For Delivery'), false);
});

test('trackingPolicy: rider must be assigned to the order', () => {
  const order = { orderStatus: 'Out For Delivery', riderId: 'rider-1' };
  assert.equal(isRiderAssigned(order, 'rider-1'), true);
  assert.equal(isRiderAssigned(order, 'rider-2'), false);
  assert.equal(
    canUpdateLocation({ orderStatus: 'Out For Delivery', riderId: null }, 'rider-1')
      .allowed,
    false,
  );
  const unassigned = canUpdateLocation(
    { orderStatus: 'Out For Delivery', riderId: null },
    'rider-1',
  );
  assert.ok(!unassigned.allowed && unassigned.reason === 'not_assigned');
});

test('trackingPolicy: location update rejected when order no longer active', () => {
  const decision = canUpdateLocation(
    { orderStatus: 'Delivered', riderId: 'rider-1' },
    'rider-1',
  );
  assert.ok(!decision.allowed && decision.reason === 'not_out_for_delivery');
});

test('trackingPolicy: stale locations are unavailable', () => {
  const now = new Date('2026-08-19T10:00:00Z');
  assert.equal(
    isLocationStale(new Date('2026-08-19T09:00:00Z'), 45_000, now),
    true,
  );
  assert.equal(
    isLocationStale(new Date('2026-08-19T09:59:30Z'), 45_000, now),
    false,
  );
  assert.equal(isLocationStale(null, 45_000, now), true);
  assert.equal(isLocationStale(undefined, 45_000, now), true);
  assert.equal(isLocationStale('garbage', 45_000, now), true);
});

test('LiveLocation model: TTL failsafe index on updatedAt expires stale records', () => {
  const indexes = LiveLocation.schema.indexes();
  const ttlIndex = indexes.find(([fields]) =>
    Object.prototype.hasOwnProperty.call(fields, 'updatedAt'),
  );
  assert.ok(ttlIndex, 'expected a TTL index on updatedAt');
  assert.equal(ttlIndex[1].expireAfterSeconds, 1800);
});

test('LiveLocation model: one record per order (no location history)', () => {
  const indexes = LiveLocation.schema.indexes();
  const uniqueIndex = indexes.find(([fields]) =>
    Object.prototype.hasOwnProperty.call(fields, 'orderId'),
  );
  assert.ok(uniqueIndex, 'expected an index on orderId');
  assert.equal(uniqueIndex[1].unique, true);
});

test('Order model: rider assignment field exists', () => {
  const schema = Order.schema.path('riderId');
  assert.ok(schema, 'riderId path expected on Order schema');
});