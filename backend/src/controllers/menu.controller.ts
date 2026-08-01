import { Request, Response, NextFunction } from 'express';
import * as menuService from '../services/menu.service';
import { HTTP_STATUS } from '../constants';

export async function getAllMenu(
  _req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const items = await menuService.getAllMenuItems();
    res.set('Cache-Control', 'no-store, no-cache, must-revalidate');
    res.status(HTTP_STATUS.OK).json({
      success: true,
      message: 'Menu fetched successfully',
      count: items.length,
      data: items,
    });
  } catch (error) {
    next(error);
  }
}

export async function getMenuItem(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const item = await menuService.getMenuItemById(req.params.id);
    res.set('Cache-Control', 'no-store, no-cache, must-revalidate');
    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: item,
    });
  } catch (error) {
    next(error);
  }
}

export async function getCategories(
  _req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const categories = await menuService.getCategories();
    res.status(HTTP_STATUS.OK).json({
      success: true,
      data: categories,
    });
  } catch (error) {
    next(error);
  }
}
