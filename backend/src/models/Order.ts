import mongoose, { Schema, Document } from 'mongoose';
import { OrderStatus, PaymentMethod, PaymentStatus } from '../types';

export interface IOrderItem {
  menuItemId: mongoose.Types.ObjectId;
  name: string;
  price: number;
  quantity: number;
  image: string;
  category: string;
  veg: boolean;
  subtotal: number;
}

export interface IOrder extends Document {
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
  estimatedDeliveryTime?: Date;
  expiresAt?: Date | null;
  completedAt?: Date | null;
  createdAt: Date;
  updatedAt: Date;
  latitude?: number;
  longitude?: number;
}

const orderItemSchema = new Schema<IOrderItem>(
  {
    menuItemId: {
      type: Schema.Types.ObjectId,
      ref: 'Menu',
      required: [true, 'Menu item ID is required'],
    },
    name: {
      type: String,
      required: [true, 'Item name is required'],
      trim: true,
    },
    price: {
      type: Number,
      required: [true, 'Item price is required'],
      min: [0, 'Price cannot be negative'],
    },
    quantity: {
      type: Number,
      required: [true, 'Quantity is required'],
      min: [1, 'Quantity must be at least 1'],
    },
    image: {
      type: String,
      default: '',
    },
    category: {
      type: String,
      required: [true, 'Category is required'],
      trim: true,
    },
    veg: {
      type: Boolean,
      required: [true, 'Veg status is required'],
    },
    subtotal: {
      type: Number,
      required: [true, 'Item subtotal is required'],
      min: [0, 'Item subtotal cannot be negative'],
    },
  },
  { _id: false },
);

const orderSchema = new Schema<IOrder>(
  {
    orderId: {
      type: String,
      required: true,
    },
    customerName: {
      type: String,
      required: [true, 'Customer name is required'],
      trim: true,
      minlength: [2, 'Name must be at least 2 characters'],
      maxlength: [60, 'Name must not exceed 60 characters'],
    },
    phone: {
      type: String,
      required: [true, 'Phone number is required'],
      trim: true,
      match: [/^\d{10}$/, 'Phone must be a 10-digit number'],
    },
    address: {
      type: String,
      required: [true, 'Delivery address is required'],
      trim: true,
    },
    landmark: {
      type: String,
      trim: true,
    },
    notes: {
      type: String,
      trim: true,
    },
    items: {
      type: [orderItemSchema],
      required: [true, 'At least one item is required'],
      validate: {
        validator: (v: IOrderItem[]) => v.length > 0,
        message: 'Order must contain at least one item',
      },
    },
    subtotal: {
      type: Number,
      required: true,
      min: [0, 'Subtotal cannot be negative'],
    },
    deliveryCharge: {
      type: Number,
      required: true,
      default: 30,
      min: [0, 'Delivery charge cannot be negative'],
    },
    total: {
      type: Number,
      required: true,
      min: [0, 'Total cannot be negative'],
    },
    paymentMethod: {
      type: String,
      default: PaymentMethod.CashOnDelivery,
      enum: Object.values(PaymentMethod),
    },
    paymentStatus: {
      type: String,
      default: PaymentStatus.Pending,
      enum: Object.values(PaymentStatus),
    },
    orderStatus: {
      type: String,
      default: OrderStatus.Pending,
      enum: Object.values(OrderStatus),
    },
    estimatedDeliveryTime: {
      type: Date,
    },
    expiresAt: {
      type: Date,
      default: null,
    },
    latitude: {
      type: Number,
    },
    longitude: {
      type: Number,
    },
    completedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  },
);

orderSchema.index({ orderId: 1 }, { unique: true });
orderSchema.index({ phone: 1 });
orderSchema.index({ orderStatus: 1 });
orderSchema.index({ createdAt: -1 });

// TTL index: auto-delete completed orders (Delivered, Cancelled) after 24 hours
orderSchema.index(
  { completedAt: 1 },
  {
    expireAfterSeconds: 86400, // 24 hours = 86400 seconds
    partialFilterExpression: {
      orderStatus: { $in: ['Delivered', 'Cancelled'] },
    },
  },
);

export const Order = mongoose.model<IOrder>('Order', orderSchema);
