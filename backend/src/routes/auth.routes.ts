import { Router } from 'express';
import { body } from 'express-validator';
import { login } from '../controllers/auth.controller';
import { validate } from '../middlewares/validate';

const router = Router();

router.post(
  '/login',
  [
    body('mobile').isString().isLength({ min: 10, max: 10 }).withMessage('Valid 10-digit mobile is required'),
    body('password').isString().notEmpty().withMessage('Password is required'),
  ],
  validate,
  login,
);

export default router;