import { connectDatabase, disconnectDatabase } from '../config/database';
import { Menu } from '../models/Menu';

interface SeedMenuItem {
  name: string;
  category: string;
  price: number;
  description: string;
  image: string;
  veg: boolean;
  available: boolean;
}

const menuData: SeedMenuItem[] = [
  { name: 'Chicken Biryani Half (1 Piece, 1 Egg)', category: 'Biryani', price: 100, description: 'Chicken Biryani Half (1 Piece, 1 Egg)', image: 'https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/public/pawan/pawan%20biryani%20images/chicken%20biryani%20half%201%20piece%20and%201%20egg.png', veg: false, available: true },
  { name: 'Chicken Biryani Full (2 Pieces, 1 Egg)', category: 'Biryani', price: 150, description: 'Chicken Biryani Full (2 Pieces, 1 Egg)', image: 'https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/public/pawan/pawan%20biryani%20images/chicken%20biryani%20full%202%20%20piece%20and%201%20egg.png', veg: false, available: true },
  { name: 'Chicken Leg Biryani Half (1 Piece, 1 Egg)', category: 'Biryani', price: 110, description: 'Chicken Leg Biryani Half (1 Piece, 1 Egg)', image: 'https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/public/pawan/pawan%20biryani%20images/chicken%20leg%20biryani%20half%201%20piece%20and%201%20egg.png', veg: false, available: true },
  { name: 'Chicken Leg Biryani Full (2 Pieces, 1 Egg)', category: 'Biryani', price: 160, description: 'Chicken Leg Biryani Full (2 Pieces, 1 Egg)', image: 'https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/public/pawan/pawan%20biryani%20images/chicken%20leg%20biryani%20full%202%20piece%20and%201%20egg.png', veg: false, available: true },
  { name: 'Mutton Biryani Half (1 Piece, 1 Egg)', category: 'Biryani', price: 140, description: 'Mutton Biryani Half (1 Piece, 1 Egg)', image: 'https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/public/pawan/pawan%20biryani%20images/mutton%20biryani%20half%201%20piece%20and%201%20egg.png', veg: false, available: true },
  { name: 'Mutton Biryani Full (2 Pieces, 1 Egg)', category: 'Biryani', price: 240, description: 'Mutton Biryani Full (2 Pieces, 1 Egg)', image: 'https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/public/pawan/pawan%20biryani%20images/mutton%20biryani%20full%20plate%202%20piece%20and%201%20egg.png', veg: false, available: true },
  { name: 'Kolkata Dum Biryani', category: 'Biryani', price: 110, description: 'Kolkata Dum Biryani', image: 'https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/public/pawan/pawan%20biryani%20images/kolkata%20chicken%20dum%20biryani%20half%201%20piece%20and%201%20aloo.png', veg: false, available: true },
  { name: 'Chicken Biryani Half (Without Egg, 1 Piece, 1 Potato)', category: 'Biryani', price: 120, description: 'Chicken Biryani Half (Without Egg, 1 Piece, 1 Potato)', image: 'https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/public/pawan/pawan%20biryani%20images/chicken%20leg%20biryani%20half%201%20piece%20and%201%20egg.png', veg: false, available: true },
  { name: 'Chicken Biryani Special (2 Pieces, 1 Potato)', category: 'Biryani', price: 170, description: 'Chicken Biryani Special (2 Pieces, 1 Potato)', image: 'https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/public/pawan/pawan%20biryani%20images/mutton%20dum%20biryani%20full%202%20piece%20and%201%20aloo.png', veg: false, available: true },
  { name: 'Mutton Biryani Half (Without Egg, 1 Piece, 1 Potato)', category: 'Biryani', price: 170, description: 'Mutton Biryani Half (Without Egg, 1 Piece, 1 Potato)', image: 'https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/public/pawan/pawan%20biryani%20images/mutton%20biryani%20half%201%20piece%20and%201%20egg.png', veg: false, available: true },
  { name: 'Mutton Biryani Special (2 Pieces)', category: 'Biryani', price: 270, description: 'Mutton Biryani Special (2 Pieces)', image: 'https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/public/pawan/pawan%20biryani%20images/mutton%20dum%20biryani%20full%202%20piece%20and%201%20aloo.png', veg: false, available: true },
  { name: 'Aloo (Potato) Biryani', category: 'Biryani', price: 70, description: 'Aloo (Potato) Biryani', image: 'https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/public/pawan/pawan%20biryani%20images/aloo%20biryani.png', veg: true, available: true },
];

async function seed(): Promise<void> {
  await connectDatabase();

  console.log('\n--- Seeding Menu ---');
  let insertedCount = 0;
  let updatedCount = 0;

  for (const item of menuData) {
    const result = await Menu.findOneAndUpdate(
      { name: item.name },
      { $set: item },
      { upsert: true, new: true, runValidators: true }
    );
    if (result.createdAt?.getTime() === result.updatedAt?.getTime()) {
      insertedCount++;
    } else {
      updatedCount++;
    }
  }

  console.log(`Menu seed complete: ${insertedCount} inserted, ${updatedCount} updated.`);

  console.log('\n--- Verification ---');
  const menuCount = await Menu.countDocuments();
  console.log(`Menu items in DB: ${menuCount}`);

  await disconnectDatabase();

  if (menuCount === 0) {
    console.error('ERROR: Menu collection is empty!');
    process.exit(1);
  }

  console.log('\nSeed completed successfully.');
}

seed().catch((error) => {
  console.error('Seed failed:', error);
  process.exit(1);
});