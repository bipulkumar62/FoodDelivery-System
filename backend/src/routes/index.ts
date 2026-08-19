import { Router } from 'express';
import healthRoutes from './healthRoutes';
import menuRoutes from './menu.routes';
import ordersRoutes from './orders.routes';
import usersRoutes from './usersRoutes';
import authRoutes from './auth.routes';
import settingsRoutes from './settings.routes';
import adminRoutes from './admin.routes';
import trackingRoutes from './tracking.routes';

const router = Router();

router.use('/health', healthRoutes);
router.use('/menu', menuRoutes);
router.use('/orders', ordersRoutes);
router.use('/users', usersRoutes);
router.use('/auth', authRoutes);
router.use('/settings', settingsRoutes);
router.use('/admin', adminRoutes);
router.use('/tracking', trackingRoutes);

export default router;
