import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';

dotenv.config();

const MONGODB_URI = process.env.MONGODB_URI || '';
const ADMIN_MOBILE = process.env.ADMIN_MOBILE || '';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || '';

async function seedAdmin() {
  if (!MONGODB_URI) {
    console.error('MONGODB_URI is required in environment');
    process.exit(1);
  }

  if (!ADMIN_MOBILE || !ADMIN_PASSWORD) {
    console.log('ADMIN_MOBILE and ADMIN_PASSWORD not set. Skipping admin seed.');
    process.exit(0);
  }

  try {
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    const adminSchema = new mongoose.Schema({
      mobile: {
        type: String,
        required: true,
        unique: true,
        trim: true,
      },
      password: {
        type: String,
        required: true,
      },
    }, { timestamps: true });

    adminSchema.pre('save', async function (next) {
      if (!this.isModified('password')) return next();
      this.password = await bcrypt.hash(this.password, 12);
      next();
    });

    const Admin = mongoose.model('Admin', adminSchema);

    const existing = await Admin.findOne({ mobile: ADMIN_MOBILE });
    if (existing) {
      existing.password = ADMIN_PASSWORD;
      await existing.save();
      console.log('Admin password updated');
    } else {
      await new Admin({ mobile: ADMIN_MOBILE, password: ADMIN_PASSWORD }).save();
      console.log('Admin created successfully');
    }
  } catch (error) {
    console.error('Error seeding admin:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
    process.exit(0);
  }
}

seedAdmin();
