import mongoose, { Schema, Document } from 'mongoose';

export interface IMenuItem extends Document {
  name: string;
  category: string;
  price: number;
  description: string;
  image: string;
  veg: boolean;
  available: boolean;
  deleted: boolean;
  deletedAt?: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

const menuSchema = new Schema<IMenuItem>(
  {
    name: {
      type: String,
      required: [true, 'Item name is required'],
      trim: true,
    },
    category: {
      type: String,
      required: [true, 'Category is required'],
      trim: true,
      lowercase: true,
    },
    price: {
      type: Number,
      required: [true, 'Price is required'],
      min: [1, 'Price must be at least 1'],
    },
    description: {
      type: String,
      default: '',
      trim: true,
    },
    image: {
      type: String,
      default: '',
    },
    veg: {
      type: Boolean,
      default: true,
    },
    available: {
      type: Boolean,
      default: true,
    },
    deleted: {
      type: Boolean,
      default: false,
    },
    deletedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  },
);

menuSchema.index({ category: 1 });
menuSchema.index({ available: 1 });
menuSchema.index({ name: 1, category: 1 }, { unique: true });

export const Menu = mongoose.model<IMenuItem>('Menu', menuSchema);
