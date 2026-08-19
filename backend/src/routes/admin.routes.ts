import { Router } from 'express';
import { body, param, query } from 'express-validator';
import {
  getAllOrders,
  updateOrderStatus,
  getAllMenuAdmin,
  createMenuItem,
  updateMenuItem,
  updateMenuItemAvailability,
  deleteMenuItem,
  assignRiderToOrder,
  getRiders,
  createRider,
} from '../controllers/admin.controller';
import * as revenueController from '../controllers/revenue.controller';
import { authenticate } from '../middlewares/auth';
import { validate } from '../middlewares/validate';
import * as settingsController from '../controllers/restaurantSettings.controller';

const router = Router();

router.use(authenticate);

const isHttpUrl = (value: unknown): boolean => {
  if (typeof value !== 'string') return false;
  const trimmed = value.trim();
  if (trimmed === '') return true;
  return /^https?:\/\/[^\s]+$/i.test(trimmed);
};

const isFinitePositiveNumber = (value: unknown): boolean =>
  typeof value === 'number' &&
  Number.isFinite(value) &&
  value > 0;

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

router.patch(
  '/orders/:id/rider',
  [
    param('id').isMongoId().withMessage('Invalid order ID'),
    body('riderId')
      .optional({ nullable: true })
      .isString()
      .withMessage('riderId must be a string'),
  ],
  validate,
  assignRiderToOrder,
);

// Riders
router.get('/riders', getRiders);

router.post(
  '/riders',
  [
    body('name')
      .isString()
      .trim()
      .notEmpty()
      .withMessage('Rider name is required'),
    body('mobile')
      .isString()
      .isLength({ min: 10, max: 10 })
      .withMessage('Valid 10-digit mobile is required'),
    body('password')
      .isString()
      .isLength({ min: 6 })
      .withMessage('Password must be at least 6 characters'),
  ],
  validate,
  createRider,
);

// Menu
router.get('/menu', getAllMenuAdmin);

router.post(
  '/menu',
  [
    body('name')
      .isString()
      .withMessage('Name is required')
      .trim()
      .notEmpty()
      .withMessage('Name is required'),
    body('price')
      .exists()
      .withMessage('Price is required')
      .custom(isFinitePositiveNumber)
      .withMessage('Price must be a finite number greater than zero'),
    body('category')
      .isString()
      .withMessage('Category is required')
      .trim()
      .notEmpty()
      .withMessage('Category is required'),
    body('description').optional().isString().withMessage('Description must be a string'),
    body('image')
      .optional()
      .custom(isHttpUrl)
      .withMessage('Image must be a valid HTTP or HTTPS URL'),
    body('veg').optional().isBoolean().withMessage('veg must be a boolean'),
    body('available').optional().isBoolean().withMessage('available must be a boolean'),
    body('isActive').optional().isBoolean().withMessage('isActive must be a boolean'),
    body('_id').not().exists().withMessage('_id cannot be set manually'),
    body('createdAt').not().exists().withMessage('createdAt cannot be set manually'),
    body('updatedAt').not().exists().withMessage('updatedAt cannot be set manually'),
  ],
  validate,
  createMenuItem,
);

router.patch(
  '/menu/:id',
  [
    param('id').isMongoId().withMessage('Invalid menu item ID'),
    body('name')
      .optional()
      .isString()
      .withMessage('Name must be a string')
      .trim()
      .notEmpty()
      .withMessage('Name must not be empty'),
    body('price')
      .optional()
      .custom(isFinitePositiveNumber)
      .withMessage('Price must be a finite number greater than zero'),
    body('category')
      .optional()
      .isString()
      .withMessage('Category must be a string')
      .trim()
      .notEmpty()
      .withMessage('Category must not be empty'),
    body('description').optional().isString().withMessage('Description must be a string'),
    body('image')
      .optional()
      .custom(isHttpUrl)
      .withMessage('Image must be a valid HTTP or HTTPS URL'),
    body('veg').optional().isBoolean().withMessage('veg must be a boolean'),
    body('available').optional().isBoolean().withMessage('available must be a boolean'),
    body('isActive').optional().isBoolean().withMessage('isActive must be a boolean'),
    body('_id').not().exists().withMessage('_id cannot be modified'),
    body('createdAt').not().exists().withMessage('createdAt cannot be modified'),
    body('updatedAt').not().exists().withMessage('updatedAt cannot be modified'),
  ],
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