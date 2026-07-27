import { Router } from 'express';
import { getAllMenu, getMenuByCategory, getMenuItem } from '../controllers/menuController';

const router = Router();

router.get('/', getAllMenu);
router.get('/category/:category', getMenuByCategory);
router.get('/:id', getMenuItem);

export default router;
