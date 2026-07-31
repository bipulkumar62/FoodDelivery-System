import { body, param } from 'express-validator';

export const createOrderValidator = [
  body('customerName')
    .isString()
    .trim()
    .isLength({ min: 2, max: 60 })
    .withMessage('Customer name must be between 2 and 60 characters'),

  body('phone')
    .isString()
    .trim()
    .matches(/^\d{10}$/)
    .withMessage('Phone must be exactly 10 digits'),

  body('address')
    .isString()
    .trim()
    .notEmpty()
    .withMessage('Delivery address is required'),

  body('landmark')
    .optional()
    .isString()
    .trim(),

  body('notes')
    .optional()
    .isString()
    .trim(),

  body('items')
    .isArray({ min: 1 })
    .withMessage('At least one item is required'),

  body('items.*.menuItemId')
    .isString()
    .notEmpty()
    .withMessage('Menu item ID is required'),

  body('items.*.quantity')
    .isInt({ min: 1 })
    .withMessage('Quantity must be at least 1'),

  body('latitude')
    .exists()
    .withMessage('Latitude is required')
    .isFloat({ min: -90, max: 90 })
    .withMessage('Latitude must be a finite number between -90 and 90'),

  body('longitude')
    .exists()
    .withMessage('Longitude is required')
    .isFloat({ min: -180, max: 180 })
    .withMessage('Longitude must be a finite number between -180 and 180'),
];

export const deliveryQuoteValidator = [
  body('latitude')
    .exists()
    .withMessage('Latitude is required')
    .isFloat({ min: -90, max: 90 })
    .withMessage('Latitude must be a finite number between -90 and 90'),

  body('longitude')
    .exists()
    .withMessage('Longitude is required')
    .isFloat({ min: -180, max: 180 })
    .withMessage('Longitude must be a finite number between -180 and 180'),
];

export const orderIdParamValidator = [
  param('id')
    .isString()
    .notEmpty()
    .withMessage('Order ID is required'),
];

export const phoneParamValidator = [
  param('phone')
    .isString()
    .matches(/^\d{10}$/)
    .withMessage('Phone must be exactly 10 digits'),
];

export const updateStatusValidator = [
  param('id')
    .isString()
    .notEmpty()
    .withMessage('Order ID is required'),

  body('status')
    .isString()
    .notEmpty()
    .withMessage('Status is required'),
];


