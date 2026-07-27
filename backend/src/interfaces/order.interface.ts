export interface IOrderItemInput {
  menuItemId: string;
  quantity: number;
}

export interface IOrderItem {
  menuItemId: string;
  name: string;
  price: number;
  quantity: number;
  image: string;
  category: string;
  veg: boolean;
  subtotal: number;
}

export interface IOrderResponse {
  _id: string;
  orderId: string;
  customerName: string;
  phone: string;
  address: string;
  landmark?: string;
  notes?: string;
  items: IOrderItem[];
  subtotal: number;
  deliveryCharge: number;
  total: number;
  paymentMethod: string;
  paymentStatus: string;
  orderStatus: string;
  estimatedDeliveryTime: Date;
  completedAt?: Date | null;
  createdAt: Date;
  updatedAt: Date;
  latitude?: number;
  longitude?: number;
}

export interface PaginatedResult<T> {
  orders: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}
