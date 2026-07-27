import { Request, Response, NextFunction } from 'express';
import * as menuService from '../services/menuService';
import { HTTP_STATUS } from '../constants';

export async function getAllMenu(_req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const items = await menuService.getAllMenuItems();
    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Menu fetched successfully',
      data: items,
    });
  } catch (error) {
    next(error);
  }
}

export async function getMenuByCategory(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const items = await menuService.getMenuItemsByCategory(req.params.category);
    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Menu fetched by category',
      data: items,
    });
  } catch (error) {
    next(error);
  }
}

export async function getMenuItem(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const item = await menuService.getMenuItemById(req.params.id);
    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: item,
    });
  } catch (error) {
    next(error);
  }
}
