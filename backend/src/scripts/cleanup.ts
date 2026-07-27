import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config();

async function cleanup() {
  try {
    await mongoose.connect(process.env.MONGODB_URI!);
    console.log('Connected to MongoDB');
    
    await mongoose.connection.db?.collection('orders').deleteMany({});
    console.log('All orders deleted');
    
    await mongoose.connection.db?.collection('revenues').deleteMany({});
    console.log('All revenues deleted');
    
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

cleanup();