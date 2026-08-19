import { Rider, IRider } from '../models/Rider';

export async function findRiderByMobile(mobile: string): Promise<IRider | null> {
  return Rider.findOne({ mobile });
}

export async function findRiderById(id: string): Promise<IRider | null> {
  return Rider.findById(id);
}

export async function findActiveRiders(): Promise<IRider[]> {
  return Rider.find({ isActive: true }).sort({ name: 1 });
}

export async function createRider(data: {
  name: string;
  mobile: string;
  password: string;
}): Promise<IRider> {
  return Rider.create({
    name: data.name,
    mobile: data.mobile,
    passwordHash: data.password,
  });
}