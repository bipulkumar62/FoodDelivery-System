import { RestaurantSettings, IRestaurantSettings } from '../models/RestaurantSettings';

export const DEFAULT_RESTAURANT_NAME = 'Pawan Biryani';
export const DEFAULT_DELIVERY_RATE_PER_KM = 10;
export const DEFAULT_ACCEPTING_ORDERS = true;

export async function getSettingsOrCreate(): Promise<IRestaurantSettings> {
  const settings = await RestaurantSettings.findOne().sort({ createdAt: 1 });
  if (settings) {
    return settings;
  }
  return RestaurantSettings.create({
    restaurantName: DEFAULT_RESTAURANT_NAME,
    deliveryRatePerKm: DEFAULT_DELIVERY_RATE_PER_KM,
    acceptingOrders: DEFAULT_ACCEPTING_ORDERS,
  });
}

export async function updateSettings(
  data: Partial<
    Pick<
      IRestaurantSettings,
      'restaurantName' | 'deliveryRatePerKm' | 'acceptingOrders'
    >
  >,
): Promise<IRestaurantSettings> {
  const settings = await getSettingsOrCreate();
  if (data.restaurantName !== undefined) {
    settings.restaurantName = data.restaurantName;
  }
  if (data.deliveryRatePerKm !== undefined) {
    settings.deliveryRatePerKm = data.deliveryRatePerKm;
  }
  if (data.acceptingOrders !== undefined) {
    settings.acceptingOrders = data.acceptingOrders;
  }
  await settings.save();
  return settings;
}
