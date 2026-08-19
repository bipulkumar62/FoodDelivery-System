import { createServer } from 'http';
import { Server, Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import app from './app';
import { config } from './config';
import { connectDatabase, disconnectDatabase } from './config/database';
import * as orderRepo from './repositories/order.repository';
import { trackingService } from './services/tracking.instance';
import { orderRoom, ADMIN_ROOM } from './services/trackingEvents';

// Declare global io
declare global {
  var io: Server | undefined;
}

async function start(): Promise<void> {
  if (!config.mongodbUri) {
    console.error('MONGODB_URI is not set in .env');
    process.exit(1);
  }

  await connectDatabase();

  const httpServer = createServer(app);
  const io = new Server(httpServer, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST'],
    },
  });

  // Make io accessible globally
  global.io = io;

  io.on('connection', (socket: Socket) => {
    console.log(`Socket connected: ${socket.id}`);

    /**
     * Customer verification: joins the private room of one order only after
     * proving the phone number stored on that order. This is what prevents
     * any customer from receiving another customer's location or order data.
     */
    socket.on('tracking:join', async (payload: { orderId?: string; phone?: string }) => {
      const orderId = payload?.orderId;
      const phone = payload?.phone;
      if (!orderId || !phone) {
        socket.emit('tracking:join-error', { message: 'orderId and phone are required' });
        return;
      }
      try {
        const order = await orderRepo.findOrderById(orderId);
        if (!order || order.phone !== phone) {
          socket.emit('tracking:join-error', { message: 'Access denied' });
          return;
        }

        const room = orderRoom(order._id.toString());
        await socket.join(room);

        // Snapshot so the customer sees the current state immediately.
        const state = await trackingService.getLocationForCustomer(
          order._id.toString(),
          phone,
        );
        if (state.active && state.location) {
          socket.emit('tracking:location', state.location);
        } else {
          socket.emit('tracking:stopped', {
            orderId: order._id.toString(),
            reason: 'no_active_tracking',
          });
        }
      } catch (error) {
        socket.emit('tracking:join-error', {
          message: 'Could not join tracking room',
        });
      }
    });

    socket.on('tracking:leave', (payload: { orderId?: string }) => {
      const orderId = payload?.orderId;
      if (orderId) {
        socket.leave(orderRoom(orderId));
      }
    });

    /**
     * Admin verification: the admin screen joins the admin room to receive
     * new-order pings. Order payloads are never broadcast to everyone.
     */
    socket.on('admin:auth', (payload: { token?: string }) => {
      const token = payload?.token;
      if (!token) {
        return;
      }
      try {
        const decoded = jwt.verify(token, config.jwtSecret) as {
          id: string;
          role?: string;
        };
        if (decoded.role === 'admin') {
          socket.join(ADMIN_ROOM);
        }
      } catch (error) {
        // Invalid token: stay unauthenticated.
      }
    });

    socket.on('disconnect', () => {
      console.log(`Socket disconnected: ${socket.id}`);
    });
  });

  const server = httpServer.listen(config.port, () => {
    console.log(`[${config.nodeEnv}] Pawan Biryani backend running on port ${config.port}`);
    console.log(`Health check: http://localhost:${config.port}/api/v1/health`);
  });

  function gracefulShutdown(signal: string): void {
    console.log(`\n${signal} received. Shutting down gracefully...`);
    server.close(async () => {
      await disconnectDatabase();
      console.log('Server closed.');
      process.exit(0);
    });

    setTimeout(() => {
      console.error('Forced shutdown after 10s');
      process.exit(1);
    }, 10000);
  }

  process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
  process.on('SIGINT', () => gracefulShutdown('SIGINT'));
}

start().catch((error) => {
  console.error('Failed to start server:', error);
  process.exit(1);
});