import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config();

async function checkImage() {
  await mongoose.connect(process.env.MONGODB_URI!);
  console.log('Connected to MongoDB');

  const Menu = mongoose.model('Menu', new mongoose.Schema({ name: String, image: String }, { strict: false }));
  const items = await Menu.find({ name: { $regex: /chicken biryani half.*egg/i } });
  items.forEach(item => console.log(item.name, '=>', item.image));
  
  await mongoose.disconnect();
}

checkImage();