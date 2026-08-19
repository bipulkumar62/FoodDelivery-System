import { Admin, IAdmin } from '../models/Admin';
import { Rider, IRider } from '../models/Rider';
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

  const token = jwt.sign({ id: admin._id, role: 'admin' }, config.jwtSecret, { expiresIn: '7d' });

  return { admin, token };
}

export async function loginRider(
  mobile: string,
  password: string,
): Promise<{ rider: IRider; token: string }> {
  const rider = await Rider.findOne({ mobile });
  if (!rider) {
    throw new AppError('Invalid credentials', HTTP_STATUS.UNAUTHORIZED);
  }

  const isMatch = await rider.comparePassword(password);
  if (!isMatch) {
    throw new AppError('Invalid credentials', HTTP_STATUS.UNAUTHORIZED);
  }

  if (!rider.isActive) {
    throw new AppError('Rider account is disabled', HTTP_STATUS.UNAUTHORIZED);
  }

  const token = jwt.sign(
    { id: rider._id.toString(), role: 'rider' },
    config.jwtSecret,
    { expiresIn: '7d' },
  );

  return { rider, token };
}