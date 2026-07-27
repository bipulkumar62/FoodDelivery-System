import mongoose, { Schema, Document } from 'mongoose';

export interface IUser extends Document {
  name: string;
  mobile: string;
  address?: string;
  landmark?: string;
  latitude?: number;
  longitude?: number;
  createdAt: Date;
  updatedAt: Date;
}

const userSchema = new Schema<IUser>(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
    },
    mobile: {
      type: String,
      required: [true, 'Mobile number is required'],
      unique: true,
      trim: true,
      match: [/^\d{10}$/, 'Mobile must be a 10-digit number'],
    },
    address: {
      type: String,
      trim: true,
    },
    landmark: {
      type: String,
      trim: true,
    },
    latitude: {
      type: Number,
      min: -90,
      max: 90,
    },
    longitude: {
      type: Number,
      min: -180,
      max: 180,
    },
  },
  {
    timestamps: true,
  },
);

export const User = mongoose.model<IUser>('User', userSchema);
