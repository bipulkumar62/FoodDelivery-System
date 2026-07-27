import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config();

async function fixImages() {
  await mongoose.connect(process.env.MONGODB_URI!);
  console.log('Connected to MongoDB');

  const Menu = mongoose.model('Menu', new mongoose.Schema({ name: String, image: String, category: String, available: Boolean }, { strict: false }));
  
  const allItems = await Menu.find({ available: true });
  console.log(`Found ${allItems.length} available items`);

  // The Supabase bucket might be public now - let's use the public URL format
  // Public URL format: https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/public/images/...
  
for (const item of allItems) {
      const oldUrl = item.image;
      if (oldUrl && oldUrl.includes('/object/sign/')) {
      // Convert signed URL to public URL
      const publicUrl = oldUrl
        .replace('/object/sign/', '/object/public/')
        .split('?')[0]; // Remove token query params
      
      console.log(`Updating: ${item.name}`);
      console.log(`  Old: ${oldUrl}`);
      console.log(`  New: ${publicUrl}`);
      
      item.image = publicUrl;
      await item.save();
    }
  }

  console.log('All images updated to public URLs');
  await mongoose.disconnect();
}

fixImages().catch(console.error);