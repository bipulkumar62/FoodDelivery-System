import { Request, Response, NextFunction } from 'express';
import * as userService from '../services/userService';
import { HTTP_STATUS } from '../constants';

export async function createUser(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const user = await userService.findOrCreateUser({
      name: req.body.name,
      mobile: req.body.mobile,
      address: req.body.address,
      landmark: req.body.landmark,
      latitude: req.body.latitude,
      longitude: req.body.longitude,
    });

    const created = req.body.mobile === user.mobile && user.createdAt.getTime() === user.updatedAt.getTime();

    res.status(created ? HTTP_STATUS.CREATED : HTTP_STATUS.OK).json({
      success: true,
      message: created ? 'User created successfully' : 'User already exists',
      data: user,
    });
  } catch (error) {
    next(error);
  }
}

export async function getUserByMobile(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const user = await userService.getUserByMobile(req.params.mobile);
    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: user,
    });
  } catch (error) {
    next(error);
  }
}
