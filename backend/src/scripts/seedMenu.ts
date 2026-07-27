import { connectDatabase, disconnectDatabase } from '../config/database';
import { Menu } from '../models/Menu';

interface SeedItem {
  name: string;
  category: string;
  price: number;
  description: string;
  image: string;
  veg: boolean;
  available: boolean;
}

const items: SeedItem[] = [
  {
    name: 'Chicken Biryani Half (1 Piece, 1 Egg)',
    category: 'Biryanis',
    price: 100,
    description:
      'Half plate of aromatic chicken biryani with one tender chicken piece and one boiled egg, layered with fragrant basmati rice and traditional spices.',
    image:
      'https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/sign/images/pawan%20biryani%20images/chicken%20biryani%20half%201%20piece%20and%201%20egg.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV9lZWM1YTQxOC01Nzg2LTRjOTctYTQ3MS1mNTdhYmYzYjE1MjkiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJpbWFnZXMvcGF3YW4gYmlyeWFuaSBpbWFnZXMvY2hpY2tlbiBiaXJ5YW5pIGhhbGYgMSBwaWVjZSBhbmQgMSBlZ2cucG5nIiwic2NvcGUiOiJkb3dubG9hZCIsImlhdCI6MTc4NDczMjA1NCwiZXhwIjozNDA1OTQ0MTI3MjU0fQ.WjQA5aVk35lI5V_ttkeAcb5sWRKMC39uPN8yoT_hupw',
    veg: false,
    available: true,
  },
  {
    name: 'Chicken Biryani Full (2 Pieces, 1 Egg)',
    category: 'Biryanis',
    price: 150,
    description:
      'Full plate of signature chicken biryani featuring two succulent chicken pieces and a boiled egg, slow-cooked with premium basmati rice and aromatic spices.',
    image:
      'https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/sign/images/pawan%20biryani%20images/chicken%20biryani%20full%202%20%20piece%20and%201%20egg.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV9lZWM1YTQxOC01Nzg2LTRjOTctYTQ3MS1mNTdhYmYzYjE1MjkiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJpbWFnZXMvcGF3YW4gYmlyeWFuaSBpbWFnZXMvY2hpY2tlbiBiaXJ5YW5pIGZ1bGwgMiAgcGllY2UgYW5kIDEgZWdnLnBuZyIsInNjb3BlIjoiZG93bmxvYWQiLCJpYXQiOjE3ODQ3MzIxMDMsImV4cCI6Mzg1Nzg0NjkzNzAzfQ.43qFdzYVtJRlOTzMNgcPbWBYPH6lr6tHa2qhwxhTepc',
    veg: false,
    available: true,
  },
  {
    name: 'Chicken Leg Biryani Half (1 Piece, 1 Egg)',
    category: 'Biryanis',
    price: 110,
    description:
      'Half plate of leg biryani with one chicken leg piece and one boiled egg, cooked with fragrant basmati rice and rich masala.',
    image:
      'https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/sign/images/pawan%20biryani%20images/chicken%20leg%20biryani%20half%201%20piece%20and%201%20egg.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV9lZWM1YTQxOC01Nzg2LTRjOTctYTQ3MS1mNTdhYmYzYjE1MjkiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJpbWFnZXMvcGF3YW4gYmlyeWFuaSBpbWFnZXMvY2hpY2tlbiBsZWcgYmlyeWFuaSBoYWxmIDEgcGllY2UgYW5kIDEgZWdnLnBuZyIsInNjb3BlIjoiZG93bmxvYWQiLCJpYXQiOjE3ODQ3MzIxNTcsImV4cCI6Mzg1Nzg0NjkzNzU3fQ.xLrVmEmLXL_1ms3xk-EbN6awJrntX1lPWp--ctMsfes',
    veg: false,
    available: true,
  },
  {
    name: 'Chicken Leg Biryani Full (2 Pieces, 1 Egg)',
    category: 'Biryanis',
    price: 160,
    description:
      'Full plate of leg biryani with two chicken leg pieces and one boiled egg, layered with aromatic basmati rice and slow-cooked to perfection.',
    image:
      'https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/sign/images/pawan%20biryani%20images/chicken%20leg%20biryani%20full%202%20piece%20and%201%20egg.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV9lZWM1YTQxOC01Nzg2LTRjOTctYTQ3MS1mNTdhYmYzYjE1MjkiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJpbWFnZXMvcGF3YW4gYmlyeWFuaSBpbWFnZXMvY2hpY2tlbiBsZWcgYmlyeWFuaSBmdWxsIDIgcGllY2UgYW5kIDEgZWdnLnBuZyIsInNjb3BlIjoiZG93bmxvYWQiLCJpYXQiOjE3ODQ3MzIxOTUsImV4cCI6Mzg0MTc4NDY5Mzc5NX0.WzmnHmg2A_EK9Y4ntKoT8Al7Oeo9pLTG4unxBi6KuxU',
    veg: false,
    available: true,
  },
  {
    name: 'Mutton Biryani Half (1 Piece, 1 Egg)',
    category: 'Biryanis',
    price: 140,
    description:
      'Half plate of tender mutton biryani with one juicy mutton piece and one boiled egg, slow-cooked with premium spices and basmati rice.',
    image:
      'https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/sign/images/pawan%20biryani%20images/mutton%20biryani%20half%201%20piece%20and%201%20egg.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV9lZWM1YTQxOC01Nzg2LTRjOTctYTQ3MS1mNTdhYmYzYjE1MjkiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJpbWFnZXMvcGF3YW4gYmlyeWFuaSBpbWFnZXMvbXV0dG9uIGJpcnlhbmkgaGFsZiAxIHBpZWNlIGFuZCAxIGVnZy5wbmciLCJzY29wZSI6ImRvd25sb2FkIiwiaWF0IjoxNzg0NzMyMzIyLCJleHAiOjM4NDE3ODQ2OTM5MjJ9.7Ifpf6Ac179LIoFSEYp4DIRlWuB3WL3zNJhKMDoc-WY',
    veg: false,
    available: true,
  },
  {
    name: 'Mutton Biryani Full (2 Pieces, 1 Egg)',
    category: 'Biryanis',
    price: 240,
    description:
      'Full plate of rich mutton biryani with two tender mutton pieces and one boiled egg, fragrant with saffron and traditional dum cooking.',
    image:
      'https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/sign/images/pawan%20biryani%20images/mutton%20biryani%20full%20plate%202%20piece%20and%201%20egg.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV9lZWM1YTQxOC01Nzg2LTRjOTctYTQ3MS1mNTdhYmYzYjE1MjkiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJpbWFnZXMvcGF3YW4gYmlyeWFuaSBpbWFnZXMvbXV0dG9uIGJpcnlhbmkgZnVsbCBwbGF0ZSAyIHBpZWNlIGFuZCAxIGVnZy5wbmciLCJzY29wZSI6ImRvd25sb2FkIiwiaWF0IjoxNzg0NzMyMzUyLCJleHAiOjM4NDE3ODQ2OTM5NTJ9.ZMt8C3YXEmyvjTpvCwQSyLSdUeCqfJo297VItav6Z5c',
    veg: false,
    available: true,
  },
  {
    name: 'Kolkata Dum Biryani',
    category: 'Biryanis',
    price: 110,
    description:
      'Authentic Kolkata-style dum biryani with tender chicken, aromatic rice, and a classic potato, slow-cooked in sealed handi for that traditional flavour.',
    image:
      'https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/sign/images/pawan%20biryani%20images/chicken%20biryani%20full%202%20%20piece%20and%201%20egg.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV9lZWM1YTQxOC01Nzg2LTRjOTctYTQ3MS1mNTdhYmYzYjE1MjkiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJpbWFnZXMvcGF3YW4gYmlyeWFuaSBpbWFnZXMvY2hpY2tlbiBiaXJ5YW5pIGZ1bGwgMiAgcGllY2UgYW5kIDEgZWdnLnBuZyIsInNjb3BlIjoiZG93bmxvYWQiLCJpYXQiOjE3ODQ3MzI0NjAsImV4cCI6Mzg0MTc4NDY5NDA2MH0.DpimNWkBbDXxykxo0U87JHIo0rYLil-3m-bUPujigMg',
    veg: false,
    available: true,
  },
  {
    name: 'Chicken Biryani Half (Without Egg, 1 Piece, 1 Potato)',
    category: 'Biryanis',
    price: 120,
    description:
      'Kolkata-style half chicken biryani with one tender chicken piece and a potato, no egg. Lightly spiced and full of flavour.',
    image:
      'https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/sign/images/pawan%20biryani%20images/kolkata%20chicken%20dum%20biryani%20half%201%20piece%20and%201%20aloo.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV9lZWM1YTQxOC01Nzg2LTRjOTctYTQ3MS1mNTdhYmYzYjE1MjkiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJpbWFnZXMvcGF3YW4gYmlyeWFuaSBpbWFnZXMva29sa2F0YSBjaGlja2VuIGR1bSBiaXJ5YW5pIGhhbGYgMSBwaWVjZSBhbmQgMSBhbG9vLnBuZyIsInNjb3BlIjoiZG93bmxvYWQiLCJpYXQiOjE3ODQ3MzI1MDYsImV4cCI6Mzg0MTc4NDY5NDEwNn0.2JGIVkVTOrhotA84A7dmKtSOrv1mMFjMIF_No_ZPgy0',
    veg: false,
    available: true,
  },
  {
    name: 'Chicken Biryani Special (2 Pieces, 1 Potato)',
    category: 'Biryanis',
    price: 170,
    description:
      'Special Kolkata-style chicken biryani with two chicken pieces and a potato, slow-cooked to perfection with premium spices.',
    image:
      'https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/sign/images/pawan%20biryani%20images/chicken%20leg%20biryani%20half%201%20piece%20and%201%20egg.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV9lZWM1YTQxOC01Nzg2LTRjOTctYTQ3MS1mNTdhYmYzYjE1MjkiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJpbWFnZXMvcGF3YW4gYmlyeWFuaSBpbWFnZXMvY2hpY2tlbiBsZWcgYmlyeWFuaSBoYWxmIDEgcGllY2UgYW5kIDEgZWdnLnBuZyIsInNjb3BlIjoiZG93bmxvYWQiLCJpYXQiOjE3ODQ3MzI1NzEsImV4cCI6Mzg0MTc4NDY5NDE3MX0.J5Kb9ak2nyCAbtFwHfl1Wkjvz3Oqp5LvMkL1_87evhI',
    veg: false,
    available: true,
  },
  {
    name: 'Mutton Biryani Half (Without Egg, 1 Piece, 1 Potato)',
    category: 'Biryanis',
    price: 170,
    description:
      'Half plate of Kolkata-style mutton biryani with one succulent mutton piece and a potato, no egg. Rich and aromatic.',
    image:
      'https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/sign/images/pawan%20biryani%20images/mutton%20dum%20biryani%20half%201%20piece%20and%201%20aloo.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV9lZWM1YTQxOC01Nzg2LTRjOTctYTQ3MS1mNTdhYmYzYjE1MjkiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJpbWFnZXMvcGF3YW4gYmlyeWFuaSBpbWFnZXMvbXV0dG9uIGR1bSBiaXJ5YW5pIGhhbGYgMSBwaWVjZSBhbmQgMSBhbG9vLnBuZyIsInNjb3BlIjoiZG93bmxvYWQiLCJpYXQiOjE3ODQ3MzI2MTMsImV4cCI6Mzg0MTc4NDY5NDIxM30.lIK5OU1-tw51jU7vgwx27jTQhreCZCfe2b2Nhft471k',
    veg: false,
    available: true,
  },
  {
    name: 'Mutton Biryani Special (2 Pieces)',
    category: 'Biryanis',
    price: 270,
    description:
      'Special Kolkata-style mutton biryani with two premium mutton pieces and a potato, slow-cooked with traditional dum technique for unmatched taste.',
    image:
      'https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/sign/images/pawan%20biryani%20images/mutton%20dum%20biryani%20full%202%20piece%20and%201%20aloo.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV9lZWM1YTQxOC01Nzg2LTRjOTctYTQ3MS1mNTdhYmYzYjE1MjkiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJpbWFnZXMvcGF3YW4gYmlyeWFuaSBpbWFnZXMvbXV0dG9uIGR1bSBiaXJ5YW5pIGZ1bGwgMiBwaWVjZSBhbmQgMSBhbG9vLnBuZyIsInNjb3BlIjoiZG93bmxvYWQiLCJpYXQiOjE3ODQ3MzI2NTAsImV4cCI6Mzg0MTc4NDY5NDI1MH0.vaSUhp4AosQt3UvffXjYAGB-oShgi4HZIDgOO_VT27Y',
    veg: false,
    available: true,
  },
  {
    name: 'Aloo (Potato) Biryani',
    category: 'Biryanis',
    price: 70,
    description:
      'A flavourful potato biryani with spiced aloo layered with fragrant basmati rice. A satisfying vegetarian option packed with flavour.',
    image:
      'https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/sign/images/pawan%20biryani%20images/aloo%20biryani.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV9lZWM1YTQxOC01Nzg2LTRjOTctYTQ3MS1mNTdhYmYzYjE1MjkiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJpbWFnZXMvcGF3YW4gYmlyeWFuaSBpbWFnZXMvYWxvbyBiaXJ5YW5pLnBuZyIsInNjb3BlIjoiZG93bmxvYWQiLCJpYXQiOjE3ODQ3MzI3MDUsImV4cCI6Mzg0MTc4NDY5NDMwNX0.0FhSQOufICF53HZWmSCbVUotN077YELeJBi-OE5Nk_Q',
    veg: true,
    available: true,
  },
];

async function seedMenu(): Promise<void> {
  await connectDatabase();

  const existingCount = await Menu.countDocuments();
  if (existingCount > 0) {
    console.log('Menu already seeded.');
    await disconnectDatabase();
    return;
  }

  await Menu.insertMany(items);
  console.log('Menu seeded successfully.');

  const count = await Menu.countDocuments();
  console.log(`Total menu items in collection: ${count}`);

  await disconnectDatabase();
}

seedMenu().catch((error) => {
  console.error('Menu seed failed:', error);
  process.exit(1);
});
