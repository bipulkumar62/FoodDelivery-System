import { Router } from 'express';
import { body, param, query } from 'express-validator';
import {
  getAllOrders,
  updateOrderStatus,
  createMenuItem,
  updateMenuItem,
  updateMenuItemAvailability,
  deleteMenuItem,
} from '../controllers/admin.controller';
import * as menuController from '../controllers/menu.controller';
import * as revenueController from '../controllers/revenue.controller';
import { authenticate } from '../middlewares/auth';
import { validate } from '../middlewares/validate';
import * as settingsController from '../controllers/restaurantSettings.controller';

const router = Router();

router.use(authenticate);

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

router.patch(
  '/menu/:id/availability',
  [
    param('id').isMongoId().withMessage('Invalid menu item ID'),
    body('available').isBoolean().withMessage('available must be a boolean'),
  ],
  validate,
  updateMenuItemAvailability,
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

// Restaurant Settings
router.get('/settings', settingsController.getAdminSettings);

router.patch(
  '/settings',
  [
    body('restaurantName')
      .optional()
      .isString()
      .withMessage('restaurantName must be a string')
      .trim()
      .notEmpty()
      .withMessage('restaurantName must not be empty')
      .isLength({ max: 100 })
      .withMessage('restaurantName must be at most 100 characters'),
    body('deliveryRatePerKm')
      .optional()
      .custom(
        (value) =>
          typeof value === 'number' &&
          Number.isFinite(value) &&
          value > 0 &&
          value <= 1000,
      )
      .withMessage(
        'deliveryRatePerKm must be a finite number greater than 0 and at most 1000',
      ),
    body('acceptingOrders')
      .optional()
      .isBoolean()
      .withMessage('acceptingOrders must be a boolean'),
  ],
  validate,
  settingsController.updateSettings,
);

export default router;