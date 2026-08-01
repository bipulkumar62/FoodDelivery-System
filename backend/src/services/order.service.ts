import { OrderStatus, PaymentMethod, PaymentStatus } from '../types';
import { CreateOrderDto } from '../dtos/order.dto';
import { IOrderItem, IOrderResponse } from '../interfaces/order.interface';
import { AppError } from '../utils/AppError';
import { HTTP_STATUS } from '../constants';
import * as orderRepo from '../repositories/order.repository';
import { IOrder } from '../models/Order';
import { getSettingsOrCreate } from './restaurantSettings.service';
import {
  RESTAURANT_LATITUDE,
  RESTAURANT_LONGITUDE,
  MAX_DELIVERY_DISTANCE_KM,
  haversineDistanceKm,
  calculateDeliveryCharge,
  isWithinDeliveryRange,
  roundToOneDecimal,
} from '../utils/deliveryCalculator';

const ESTIMATED_MINUTES = 35;

export interface DeliveryQuote {
  distanceKm: number;
  deliveryRatePerKm: number;
  deliveryCharge: number;
  withinDeliveryRange: boolean;
}

const VALID_TRANSITIONS: Record<string, string[]> = {
  [OrderStatus.Pending]: [
    OrderStatus.Accepted,
    OrderStatus.Rejected,
    OrderStatus.Cancelled,
  ],
  [OrderStatus.Accepted]: [OrderStatus.Preparing],
  [OrderStatus.Preparing]: [OrderStatus.OutForDelivery],
  [OrderStatus.OutForDelivery]: [OrderStatus.Delivered],
  [OrderStatus.Delivered]: [],
  [OrderStatus.Rejected]: [],
  [OrderStatus.Cancelled]: [],
};

function isValidTransition(from: string, to: string): boolean {
  const allowed = VALID_TRANSITIONS[from];
  return allowed ? allowed.includes(to) : false;
}

async function generateOrderId(): Promise<string> {
  const lastOrderId = await orderRepo.findLastOrderId();
  let nextNum = 100001;
  if (lastOrderId) {
    const num = parseInt(lastOrderId.replace('PB', ''), 10);
    if (!isNaN(num)) {
      nextNum = num + 1;
    }
  }
  return `PB${nextNum}`;
}

/**
 * Shared delivery calculation used by both the delivery-quote endpoint
 * and order creation.
 */
export async function buildDeliveryQuote(
  latitude: number,
  longitude: number,
): Promise<DeliveryQuote> {
  const distanceKm = haversineDistanceKm(
    RESTAURANT_LATITUDE,
    RESTAURANT_LONGITUDE,
    latitude,
    longitude,
  );
  const settings = await getSettingsOrCreate();
  return {
    distanceKm: roundToOneDecimal(distanceKm),
    deliveryRatePerKm: settings.deliveryRatePerKm,
    deliveryCharge: calculateDeliveryCharge(
      distanceKm,
      settings.deliveryRatePerKm,
    ),
    withinDeliveryRange: isWithinDeliveryRange(distanceKm),
  };
}

export async function placeOrder(dto: CreateOrderDto): Promise<IOrderResponse> {
  if (dto.items.length === 0) {
    throw new AppError('At least one item is required', HTTP_STATUS.BAD_REQUEST);
  }

  const settings = await getSettingsOrCreate();
  if (!settings.acceptingOrders) {
    throw new AppError(
      'We are currently offline. Ordering is temporarily unavailable. Please try again later.',
      HTTP_STATUS.BAD_REQUEST,
    );
  }

  const quote = await buildDeliveryQuote(dto.latitude, dto.longitude);
  if (!quote.withinDeliveryRange) {
    throw new AppError(
      "Sorry, we are currently not available in your area. We'll be available soon.",
      HTTP_STATUS.BAD_REQUEST,
    );
  }

  const menuItemIds = dto.items.map((i) => i.menuItemId);
  const menuItems = await orderRepo.findMenuItemsByIds(menuItemIds);

  const menuMap = new Map(
    menuItems.map((item) => [item._id.toString(), item]),
  );

  for (const item of dto.items) {
    const menuItem = menuMap.get(item.menuItemId);
    if (!menuItem) {
      throw new AppError(
        `Menu item not found: ${item.menuItemId}`,
        HTTP_STATUS.NOT_FOUND,
      );
    }
    if (!menuItem.isActive) {
      throw new AppError(
        `Menu item not found: ${item.menuItemId}`,
        HTTP_STATUS.NOT_FOUND,
      );
    }
    if (!menuItem.available) {
      throw new AppError(
        `${menuItem.name} is currently sold out.`,
        HTTP_STATUS.BAD_REQUEST,
      );
    }
    if (item.quantity <= 0) {
      throw new AppError(
        `Invalid quantity for ${menuItem.name}`,
        HTTP_STATUS.BAD_REQUEST,
      );
    }
  }

  const items: IOrderItem[] = dto.items.map((item) => {
    const menuItem = menuMap.get(item.menuItemId)!;
    const price = menuItem.price;
    const subtotal = price * item.quantity;
    return {
      menuItemId: menuItem._id.toString(),
      name: menuItem.name,
      price,
      quantity: item.quantity,
      image: menuItem.image,
      category: menuItem.category,
      veg: menuItem.veg,
      subtotal,
    };
  });

  const subtotal = items.reduce((sum, item) => sum + item.subtotal, 0);
  const deliveryCharge = quote.deliveryCharge;
  const total = subtotal + deliveryCharge;

  const orderId = await generateOrderId();
  const estimatedDeliveryTime = new Date(
    Date.now() + ESTIMATED_MINUTES * 60 * 1000,
  );

  const order = await orderRepo.insertOrder({
    orderId,
    customerName: dto.customerName,
    phone: dto.phone,
    address: dto.address,
    landmark: dto.landmark,
    notes: dto.notes,
    items: items as any,
    subtotal,
    deliveryCharge,
    distanceKm: quote.distanceKm,
    deliveryRatePerKm: quote.deliveryRatePerKm,
    total,
    paymentMethod: PaymentMethod.CashOnDelivery,
    paymentStatus: PaymentStatus.Pending,
    orderStatus: OrderStatus.Pending,
    estimatedDeliveryTime,
    latitude: dto.latitude,
    longitude: dto.longitude,
  });

  return formatOrderResponse(order);
}

export async function getOrderById(id: string): Promise<IOrderResponse> {
  const order = await orderRepo.findOrderById(id);
  if (!order) {
    throw new AppError('Order not found', HTTP_STATUS.NOT_FOUND);
  }
  return formatOrderResponse(order);
}

export async function getOrdersByPhone(
  phone: string,
): Promise<IOrderResponse[]> {
  const orders = await orderRepo.findOrdersByPhone(phone);
  return orders.map(formatOrderResponse);
}

export async function getAllOrders(): Promise<IOrderResponse[]> {
  const orders = await orderRepo.findAllOrders();
  return orders.map(formatOrderResponse);
}

export async function updateOrderStatus(
  id: string,
  newStatus: string,
): Promise<IOrderResponse> {
  const validStatuses = Object.values(OrderStatus) as string[];
  if (!validStatuses.includes(newStatus)) {
    throw new AppError(
      `Invalid status. Allowed: ${validStatuses.join(', ')}`,
      HTTP_STATUS.BAD_REQUEST,
    );
  }

  const currentOrder = await orderRepo.findOrderById(id);
  if (!currentOrder) {
    throw new AppError('Order not found', HTTP_STATUS.NOT_FOUND);
  }

  if (!isValidTransition(currentOrder.orderStatus, newStatus)) {
    throw new AppError(
      `Cannot transition from "${currentOrder.orderStatus}" to "${newStatus}"`,
      HTTP_STATUS.BAD_REQUEST,
    );
  }

  // Set completedAt only when order is delivered or cancelled for the first time
  const completedAt =
    (newStatus === OrderStatus.Delivered || newStatus === OrderStatus.Cancelled) &&
    !currentOrder.completedAt
      ? new Date()
      : undefined;

  const updatedOrder = await orderRepo.findOrderAndUpdateStatus(
    id,
    newStatus,
    completedAt,
  );
  if (!updatedOrder) {
    throw new AppError('Order not found', HTTP_STATUS.NOT_FOUND);
  }

  return formatOrderResponse(updatedOrder);
}

function formatOrderResponse(order: IOrder): IOrderResponse {
  return {
    _id: order._id.toString(),
    orderId: order.orderId,
    customerName: order.customerName,
    phone: order.phone,
    address: order.address,
    landmark: order.landmark,
    notes: order.notes,
    items: order.items.map((item) => ({
      menuItemId: item.menuItemId.toString(),
      name: item.name,
      price: item.price,
      quantity: item.quantity,
      image: item.image,
      category: item.category,
      veg: item.veg,
      subtotal: item.subtotal,
    })),
    subtotal: order.subtotal,
    deliveryCharge: order.deliveryCharge,
    distanceKm: order.distanceKm,
    deliveryRatePerKm: order.deliveryRatePerKm,
    total: order.total,
    paymentMethod: order.paymentMethod,
    paymentStatus: order.paymentStatus,
    orderStatus: order.orderStatus,
    estimatedDeliveryTime: order.estimatedDeliveryTime!,
    completedAt: order.completedAt ?? null,
    createdAt: order.createdAt,
    updatedAt: order.updatedAt,
    latitude: order.latitude,
    longitude: order.longitude,
  };
}
