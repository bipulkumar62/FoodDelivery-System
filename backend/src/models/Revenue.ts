import mongoose, { Schema, Document } from 'mongoose';

export interface IRevenue extends Document {
  date: Date; // Date for which revenue is tracked (start of day)
  totalAmount: number;
  deliveredOrderCount: number;
  orderIds: mongoose.Types.ObjectId[];
  createdAt: Date;
  updatedAt: Date;
}

const revenueSchema = new Schema<IRevenue>(
  {
    date: {
      type: Date,
      required: true,
      unique: true,
    },
    totalAmount: {
      type: Number,
      required: true,
      default: 0,
      min: 0,
    },
    deliveredOrderCount: {
      type: Number,
      required: true,
      default: 0,
      min: 0,
    },
    orderIds: [{
      type: Schema.Types.ObjectId,
      ref: 'Order',
    }],
  },
  {
    timestamps: true,
  },
);

revenueSchema.index({ date: -1 });

export const Revenue = mongoose.model<IRevenue>('Revenue', revenueSchema);