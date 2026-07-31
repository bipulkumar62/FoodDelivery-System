import mongoose, { Schema, Document } from 'mongoose';

export interface IRestaurantSettings extends Document {
  restaurantName: string;
  deliveryRatePerKm: number;
  acceptingOrders: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const restaurantSettingsSchema = new Schema<IRestaurantSettings>(
  {
    restaurantName: {
      type: String,
      required: [true, 'Restaurant name is required'],
      trim: true,
      maxlength: [100, 'Restaurant name must be at most 100 characters'],
      default: 'Pawan Biryani',
    },
    deliveryRatePerKm: {
      type: Number,
      required: [true, 'Delivery rate per km is required'],
      default: 10,
      min: [1, 'Delivery rate must be greater than 0'],
      max: [1000, 'Delivery rate must be at most 1000'],
    },
    acceptingOrders: {
      type: Boolean,
      required: [true, 'acceptingOrders is required'],
      default: true,
    },
  },
  {
    timestamps: true,
  },
);

export const RestaurantSettings = mongoose.model<IRestaurantSettings>(
  'RestaurantSettings',
  restaurantSettingsSchema,
);
