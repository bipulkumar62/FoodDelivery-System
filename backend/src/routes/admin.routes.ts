import { Router } from 'express';
import { body, param, query } from 'express-validator';
import {
  getAllOrders,
  updateOrderStatus,
  createMenuItem,
  updateMenuItem,
  deleteMenuItem,
} from '../controllers/admin.controller';
import * as menuController from '../controllers/menu.controller';
import * as revenueController from '../controllers/revenue.controller';
import { validate } from '../middlewares/validate';

const router = Router();

// Orders
router.get('/orders', getAllOrders);

router.patch(
  '/orders/:id/status',
  [
    param('id').isMongoId().withMessage('Invalid order ID'),
    body('status').isString().notEmpty().withMessage('Status is required'),
  ],
  validate,
  updateOrderStatus,
);

// Menu
router.get('/menu', menuController.getAllMenu);

router.post(
  '/menu',
  [
    body('name').isString().notEmpty().withMessage('Name is required'),
    body('price').isNumeric().withMessage('Price must be a number'),
    body('category').isString().notEmpty().withMessage('Category is required'),
    body('image').optional().isString(),
    body('available').optional().isBoolean(),
    body('veg').optional().isBoolean(),
  ],
  validate,
  createMenuItem,
);

router.patch(
  '/menu/:id',
  [param('id').isMongoId().withMessage('Invalid menu item ID')],
  validate,
  updateMenuItem,
);

router.delete(
  '/menu/:id',
  [param('id').isMongoId().withMessage('Invalid menu item ID')],
  validate,
  deleteMenuItem,
);

// Revenue
router.get('/revenue', revenueController.getRevenue);
router.delete('/revenue', revenueController.deleteRevenue);
router.get(
  '/revenue/history',
  [query('limit').optional().isInt({ min: 1, max: 365 }).withMessage('Limit must be between 1 and 365')],
  validate,
  revenueController.getRevenueHistory,
);

export default router;