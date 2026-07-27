import { Router } from 'express';
import {
  createOrder,
  getOrderById,
  getOrdersByPhone,
  getAllOrders,
  updateOrderStatus,
} from '../controllers/orders.controller';
import {
  createOrderValidator,
  orderIdParamValidator,
  phoneParamValidator,
  updateStatusValidator,
} from '../validators/order.validator';
import { validate } from '../middlewares/validate';

const router = Router();

router.post(
  '/',
  createOrderValidator,
  validate,
  createOrder,
);

router.get('/', getAllOrders);

router.get(
  '/phone/:phone',
  phoneParamValidator,
  validate,
  getOrdersByPhone,
);

router.patch(
  '/:id/status',
  updateStatusValidator,
  validate,
  updateOrderStatus,
);

router.get(
  '/:id',
  orderIdParamValidator,
  validate,
  getOrderById,
);

export default router;
