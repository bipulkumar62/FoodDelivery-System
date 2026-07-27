import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';

dotenv.config();

const MONGODB_URI = process.env.MONGODB_URI || '';

async function seedAdmin() {
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

    const mobile = '9304901506';
    const password = 'yash@70000000';

    const existing = await Admin.findOne({ mobile });
    if (existing) {
      console.log('Admin already exists, updating password...');
      existing.password = await bcrypt.hash(password, 12);
      await existing.save();
      console.log('Admin password updated');
    } else {
      const admin = new Admin({ mobile, password });
      await admin.save();
      console.log('Admin created successfully');
    }

    console.log('Mobile:', mobile);
    console.log('Password:', password);
    console.log('Login with these credentials');
  } catch (error) {
    console.error('Error seeding admin:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
    process.exit(0);
  }
}

seedAdmin();