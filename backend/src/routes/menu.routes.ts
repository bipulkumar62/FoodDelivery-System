import { Router } from 'express';
import {
  getAllMenu,
  getMenuItem,
} from '../controllers/menu.controller';

const router = Router();

router.get('/', getAllMenu);
router.get('/:id', getMenuItem);

export default router;
