import { Router } from 'express';
import { getPublicSettings } from '../controllers/restaurantSettings.controller';

const router = Router();

router.get('/', getPublicSettings);

export default router;
