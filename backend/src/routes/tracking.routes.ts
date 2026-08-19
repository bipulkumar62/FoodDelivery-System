import { Router } from 'express';
import { body, param, query } from 'express-validator';
import { validate } from '../middlewares/validate';
import { authenticateRider } from '../middlewares/authenticateRider';
import {
  startTracking,
  updateLocation,
  stopTracking,
  getLocationForCustomer,
} from '../controllers/tracking.controller';

const router = Router();

const isLatitude = (value: unknown): boolean =>
  typeof value === 'number' && Number.isFinite(value) && value >= -90 && value <= 90;

const isLongitude = (value: unknown): boolean =>
  typeof value === 'number' &&
  Number.isFinite(value) &&
  value >= -180 &&
  value <= 180;

// Rider-authenticated endpoints.
router.post('/:orderId/start', authenticateRider, startTracking);

router.put(
  '/:orderId/location',
  authenticateRider,
  [
    param('orderId').isString().notEmpty().withMessage('Order ID is required'),
    body('latitude').custom(isLatitude).withMessage('Invalid latitude'),
    body('longitude').custom(isLongitude).withMessage('Invalid longitude'),
    body('accuracy')
      .optional()
      .isFloat({ min: 0, max: 5000 })
      .withMessage('Invalid accuracy'),
  ],
  validate,
  updateLocation,
);

router.post('/:orderId/stop', authenticateRider, stopTracking);

// Customer read: phone must match the order's phone.
router.get(
  '/:orderId/location',
  [
    param('orderId').isString().notEmpty().withMessage('Order ID is required'),
    query('phone')
      .isString()
      .notEmpty()
      .withMessage('Phone is required to view tracking'),
  ],
  validate,
  getLocationForCustomer,
);

export default router;