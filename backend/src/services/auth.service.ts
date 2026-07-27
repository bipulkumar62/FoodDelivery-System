import { Admin, IAdmin } from '../models/Admin';
import { AppError } from '../utils/AppError';
import { HTTP_STATUS } from '../constants';
import jwt from 'jsonwebtoken';
import { config } from '../config';

export async function loginAdmin(mobile: string, password: string): Promise<{ admin: IAdmin; token: string }> {
  const admin = await Admin.findOne({ mobile });
  if (!admin) {
    throw new AppError('Invalid credentials', HTTP_STATUS.UNAUTHORIZED);
  }

  const isMatch = await admin.comparePassword(password);
  if (!isMatch) {
    throw new AppError('Invalid credentials', HTTP_STATUS.UNAUTHORIZED);
  }

  const token = jwt.sign({ id: admin._id }, config.jwtSecret, { expiresIn: '7d' });

  return { admin, token };
}