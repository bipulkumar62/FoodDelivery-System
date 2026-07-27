import { createServer } from 'http';
import { Server, Socket } from 'socket.io';
import app from './app';
import { config } from './config';
import { connectDatabase, disconnectDatabase } from './config/database';

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
