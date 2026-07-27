import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config();

async function updateSpecificImage() {
  await mongoose.connect(process.env.MONGODB_URI!);
  console.log('Connected to MongoDB');

  const Menu = mongoose.model('Menu', new mongoose.Schema({ name: String, image: String }, { strict: false }));
  
  // Use a publicly accessible biryani image from a reliable source
  const publicImageUrl = 'https://images.pexels.com/photos/4439740/pexels-photo-4439740.jpeg?auto=compress&cs=tinysrgb&w=800';
  
  const result = await Menu.updateOne(
    { name: 'Chicken Biryani Half (1 Piece, 1 Egg)' },
    { $set: { image: publicImageUrl } }
  );
  
  console.log('Updated:', result);
  
  const item = await Menu.findOne({ name: 'Chicken Biryani Half (1 Piece, 1 Egg)' });
  if (item) console.log('New image URL:', item.image);
  
  await mongoose.disconnect();
}

updateSpecificImage().catch(console.error);