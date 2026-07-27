import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config();

async function updateImage() {
  await mongoose.connect(process.env.MONGODB_URI!);
  console.log('Connected to MongoDB');

  const Menu = mongoose.model('Menu', new mongoose.Schema({ name: String, image: String }, { strict: false }));
  
  // Use the URL the user provided - they said this works
  const imageUrl = 'https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/public/pawan/pawan%20biryani%20images/chicken%20leg%20biryani%20half%201%20piece%20and%201%20egg.png';
  
  const result = await Menu.updateOne(
    { name: 'Chicken Biryani Half (1 Piece, 1 Egg)' },
    { $set: { image: imageUrl } }
  );
  
  console.log('Updated:', result);
  
  const item = await Menu.findOne({ name: 'Chicken Biryani Half (1 Piece, 1 Egg)' });
  if (item) console.log('New image URL:', item.image);
  
  await mongoose.disconnect();
}

updateImage().catch(console.error);