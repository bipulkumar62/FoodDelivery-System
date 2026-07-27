import { Router } from 'express';
import { body } from 'express-validator';
import { createUser, getUserByMobile } from '../controllers/usersController';
import { validate } from '../middlewares/validate';

const router = Router();

router.post(
  '/',
  [
    body('name').isString().notEmpty().withMessage('Name is required'),
    body('mobile').isString().isLength({ min: 10, max: 10 }).withMessage('Valid 10-digit mobile is required'),
    body('address').optional().isString(),
    body('landmark').optional().isString(),
    body('latitude').optional().isNumeric(),
    body('longitude').optional().isNumeric(),
  ],
  validate,
  createUser,
);

router.get('/:mobile', getUserByMobile);

export default router;
