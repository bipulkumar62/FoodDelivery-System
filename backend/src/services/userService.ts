import { User, IUser } from '../models/User';
import { AppError } from '../utils/AppError';
import { HTTP_STATUS } from '../constants';

export interface CreateUserInput {
  name: string;
  mobile: string;
  address?: string;
  landmark?: string;
  latitude?: number;
  longitude?: number;
}

export async function findOrCreateUser(input: CreateUserInput): Promise<IUser> {
  const existing = await User.findOne({ mobile: input.mobile });
  if (existing) {
    return existing;
  }

  const user = await User.create(input);
  return user;
}

export async function getUserByMobile(mobile: string): Promise<IUser> {
  const user = await User.findOne({ mobile });
  if (!user) {
    throw new AppError('User not found', HTTP_STATUS.NOT_FOUND);
  }
  return user;
}
