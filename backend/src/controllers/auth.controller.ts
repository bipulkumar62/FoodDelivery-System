import { Request, Response, NextFunction } from 'express';
import * as authService from '../services/auth.service';
import { HTTP_STATUS } from '../constants';

export async function login(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const { mobile, password } = req.body;

    if (!mobile || !password) {
      res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Mobile number and password are required',
      });
      return;
    }

    const { admin, token } = await authService.loginAdmin(mobile, password);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Login successful',
      data: {
        token,
        admin: {
          id: admin._id,
          mobile: admin.mobile,
        },
      },
    });
  } catch (error) {
    next(error);
  }
}

export async function riderLogin(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const { mobile, password } = req.body;

    if (!mobile || !password) {
      res.status(HTTP_STATUS.BAD_REQUEST).json({
        success: false,
        message: 'Mobile number and password are required',
      });
      return;
    }

    const { rider, token } = await authService.loginRider(mobile, password);

    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Rider login successful',
      data: {
        token,
        rider: {
          id: rider._id,
          name: rider.name,
          mobile: rider.mobile,
        },
      },
    });
  } catch (error) {
    next(error);
  }
}