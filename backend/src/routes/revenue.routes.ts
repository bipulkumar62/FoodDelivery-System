import { Router } from 'express';
import { getRevenue, deleteRevenue, getRevenueHistory } from '../controllers/revenue.controller';
import { authenticate } from '../middlewares/auth';
import { validate } from '../middlewares/validate';
import { query } from 'express-validator';

const router = Router();

// All revenue routes require authentication
router.use(authenticate);

router.get('/', getRevenue);
router.delete('/', deleteRevenue);
router.get(
  '/history',
  [query('limit').optional().isInt({ min: 1, max: 365 }).withMessage('Limit must be between 1 and 365')],
  validate,
  getRevenueHistory,
);

export default router;