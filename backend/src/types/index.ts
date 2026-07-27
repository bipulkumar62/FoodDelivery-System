export interface DummyResponse {
  success: boolean;
  message: string;
  data?: unknown;
}

export enum OrderStatus {
  Pending = 'Pending',
  Accepted = 'Accepted',
  Preparing = 'Preparing',
  OutForDelivery = 'Out For Delivery',
  Delivered = 'Delivered',
  Rejected = 'Rejected',
  Cancelled = 'Cancelled',
}

export enum PaymentMethod {
  CashOnDelivery = 'CashOnDelivery',
}

export enum PaymentStatus {
  Pending = 'Pending',
  Paid = 'Paid',
}
