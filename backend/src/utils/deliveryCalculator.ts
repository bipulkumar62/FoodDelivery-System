/**
 * Shared delivery calculation utilities.
 *
 * Used by both order creation and the delivery-quote endpoint so the
 * two can never drift apart.
 */

export const RESTAURANT_LATITUDE = 26.2200986;
export const RESTAURANT_LONGITUDE = 84.3471717;
export const MAX_DELIVERY_DISTANCE_KM = 15;

const EARTH_RADIUS_KM = 6371;

function toRadians(degrees: number): number {
  return (degrees * Math.PI) / 180;
}

/**
 * Great-circle distance between two coordinates in kilometres
 * (Haversine formula).
 */
export function haversineDistanceKm(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
): number {
  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return EARTH_RADIUS_KM * c;
}

/**
 * Delivery charge per the admin-configured rate:
 * Math.ceil(distanceKm) * deliveryRatePerKm
 *
 * Examples at rate 10: 0.1km -> 10, 1.0km -> 10, 1.1km -> 20,
 * 2.0km -> 20, 2.1km -> 30.
 */
export function calculateDeliveryCharge(
  distanceKm: number,
  deliveryRatePerKm: number,
): number {
  return Math.ceil(distanceKm) * deliveryRatePerKm;
}

export function isWithinDeliveryRange(distanceKm: number): boolean {
  return distanceKm <= MAX_DELIVERY_DISTANCE_KM;
}

/** Rounds to one decimal place for display purposes. */
export function roundToOneDecimal(value: number): number {
  return Math.round(value * 10) / 10;
}
