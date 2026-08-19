import mongoose, { Schema, Document } from 'mongoose';
import bcrypt from 'bcryptjs';

export interface IRider extends Document {
  name: string;
  mobile: string;
  passwordHash: string;
  isActive: boolean;
  comparePassword(password: string): Promise<boolean>;
  createdAt: Date;
  updatedAt: Date;
}

const riderSchema = new Schema<IRider>(
  {
    name: {
      type: String,
      required: [true, 'Rider name is required'],
      trim: true,
      minlength: [2, 'Rider name must be at least 2 characters'],
      maxlength: [60, 'Rider name must not exceed 60 characters'],
    },
    mobile: {
      type: String,
      required: [true, 'Rider mobile number is required'],
      unique: true,
      trim: true,
      match: [/^\d{10}$/, 'Rider mobile must be a 10-digit number'],
    },
    passwordHash: {
      type: String,
      required: [true, 'Password is required'],
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  },
);

riderSchema.pre('save', async function (next) {
  if (!this.isModified('passwordHash')) {
    return next();
  }
  try {
    const salt = await bcrypt.genSalt(10);
    this.passwordHash = await bcrypt.hash(this.passwordHash, salt);
    next();
  } catch (error) {
    next(error as Error);
  }
});

riderSchema.methods.comparePassword = function (
  password: string,
): Promise<boolean> {
  return bcrypt.compare(password, this.passwordHash);
};

export const Rider = mongoose.model<IRider>('Rider', riderSchema);