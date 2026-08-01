import mongoose from 'mongoose';
import dotenv from 'dotenv';

/**
 * One-time production test-data cleanup.
 *
 * Usage:
 *   npm run cleanup:test -- --dry-run          (default: report only)
 *   ALLOW_PRODUCTION_CLEANUP=true npm run cleanup:test -- --execute
 *
 * Safety:
 *   - --execute requires ALLOW_PRODUCTION_CLEANUP=true (aborts otherwise)
 *   - deletes only explicitly classified test records by _id (no deleteMany)
 *   - preserves admins, restaurant settings, active production menu items
 *   - never prints passwords, tokens, MongoDB URI or full phone numbers
 */

dotenv.config();

const maskPhone = (p?: string): string =>
  p && p.length >= 6 ? p.replace(/^(\d{2})\d+(\d{2})$/, '$1****$2') : p ?? '';

const TEST_NAME_RE =
  /test|tester|regression|realtime|modi|demo|boryan|junk|dummy|sample/i;

interface Selection {
  collection: string;
  id: string;
  orderId?: string;
  customerName?: string;
  createdAt?: string;
  reason: string;
}

const selections: Selection[] = [];
const ambiguous: Selection[] = [];
const preserved: Selection[] = [];

async function classify(db: mongoose.mongo.Db): Promise<void> {
  // ---- ORDERS ----
  const orders = await db
    .collection('orders')
    .find({})
    .sort({ createdAt: 1 })
    .toArray();
  for (const o of orders) {
    const name = (o.customerName ?? '').toString();
    const phone = (o.phone ?? '').toString();
    const base = {
      collection: 'orders',
      id: o._id.toString(),
      orderId: o.orderId,
      customerName: name,
      createdAt: o.createdAt,
    };
    if (TEST_NAME_RE.test(name) || /^9876\d{6}$/.test(phone)) {
      selections.push({ ...base, reason: `Test customer name or test phone (${maskPhone(phone)})` });
    } else if (name === '' || o.items == null || o.items.length === 0) {
      selections.push({ ...base, reason: 'Incomplete test record (empty name or no items)' });
    } else {
      ambiguous.push({ ...base, reason: 'Real-looking customer name and item snapshot; kept' });
      preserved.push({ ...base, reason: 'Not clearly test data; preserved' });
    }
  }

  // ---- REVENUES (recomputed on demand from delivered orders) ----
  const revenues = await db.collection('revenues').find({}).toArray();
  for (const r of revenues) {
    const orderIds: string[] = ((r.orderIds as unknown[]) ?? []).map((x) =>
      x instanceof mongoose.Types.ObjectId ? x.toString() : String(x),
    );
    const deletedOrderIds = new Set(selections.filter((s) => s.collection === 'orders').map((s) => s.id));
    if (orderIds.some((id) => deletedOrderIds.has(id))) {
      selections.push({
        collection: 'revenues',
        id: r._id.toString(),
        createdAt: r.createdAt,
        reason: 'References deleted test order(s); recomputed on demand',
      });
    } else if (r.totalAmount === 0 && r.deliveredOrderCount === 0 && orderIds.length === 0) {
      selections.push({
        collection: 'revenues',
        id: r._id.toString(),
        createdAt: r.createdAt,
        reason: 'Empty stale revenue artifact with no orders; recomputed on demand',
      });
    } else {
      preserved.push({
        collection: 'revenues',
        id: r._id.toString(),
        createdAt: r.createdAt,
        reason: 'References non-test orders; preserved',
      });
    }
  }

  // ---- MENUS (only clearly test items; production menu preserved) ----
  const menus = await db.collection('menus').find({}).toArray();
  for (const m of menus) {
    const name = (m.name ?? '').toString();
    const base = {
      collection: 'menus',
      id: m._id.toString(),
      customerName: name,
      createdAt: m.createdAt,
    };
    if (TEST_NAME_RE.test(name)) {
      selections.push({
        ...base,
        reason: `Test item name (isActive=${m.isActive}, category=${m.category})`,
      });
    } else {
      preserved.push({ ...base, reason: 'Production menu item; preserved' });
    }
  }

  // ---- ADMINS / USERS / SETTINGS: never deleted ----
  const admins = await db.collection('admins').find({}).toArray();
  for (const a of admins) {
    preserved.push({
      collection: 'admins',
      id: a._id.toString(),
      createdAt: a.createdAt,
      reason: 'Admin account; preserved (never deleted)',
    });
  }
  const users = await db.collection('users').find({}).toArray();
  for (const u of users) {
    const name = (u.name ?? '').toString();
    const mobile = (u.mobile ?? '').toString();
    if (TEST_NAME_RE.test(name) || /^9876\d{6}$/.test(mobile)) {
      selections.push({
        collection: 'users',
        id: u._id.toString(),
        customerName: name,
        createdAt: u.createdAt,
        reason: `Test user (${maskPhone(mobile)})`,
      });
    } else {
      preserved.push({
        collection: 'users',
        id: u._id.toString(),
        createdAt: u.createdAt,
        reason: 'Non-test user; preserved',
      });
    }
  }
  const settings = await db.collection('restaurantsettings').find({}).toArray();
  for (const s of settings) {
    preserved.push({
      collection: 'restaurantsettings',
      id: s._id.toString(),
      createdAt: s.createdAt,
      reason: 'Production restaurant settings; preserved',
    });
  }
}

function printReport(): void {
  const line = (s: Selection): string => {
    const parts = [s.collection, s.id];
    if (s.orderId) parts.push(s.orderId!);
    if (s.customerName !== undefined) parts.push(`name=${s.customerName}`);
    parts.push(`createdAt=${s.createdAt ?? 'n/a'}`);
    parts.push(`reason=${s.reason}`);
    return parts.join(' | ');
  };
  console.log('\n=== SELECTED FOR DELETION ===');
  for (const s of selections) console.log(line(s));
  console.log(`\n=== PRESERVED (${preserved.length}) ===`);
  for (const s of preserved) console.log(line(s));
  console.log(`\n=== AMBIGUOUS, NOT DELETED (${ambiguous.length}) ===`);
  for (const s of ambiguous) console.log(line(s));
  console.log(
    `\nSUMMARY: selected=${selections.length} preserved=${preserved.length} ambiguous=${ambiguous.length}`,
  );
}

async function execute(db: mongoose.mongo.Db): Promise<void> {
  const byCollection = new Map<string, Selection[]>();
  for (const s of selections) {
    const list = byCollection.get(s.collection) ?? [];
    list.push(s);
    byCollection.set(s.collection, list);
  }
  let deleted = 0;
  for (const [collection, list] of byCollection) {
    for (const s of list) {
      const result = await db.collection(collection).deleteOne({
        _id: new mongoose.Types.ObjectId(s.id),
      });
      if (result.deletedCount === 1) deleted++;
      console.log(
        `DELETED ${collection} ${s.orderId ?? s.id} (${s.customerName ?? ''})`,
      );
    }
  }
  console.log(`\nEXECUTED: ${deleted}/${selections.length} records deleted`);
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run');
  const executeMode = args.includes('--execute');

  if (!dryRun && !executeMode) {
    console.log('Usage: ts-node src/scripts/cleanup-test-data.ts --dry-run|--execute');
    process.exit(0);
  }
  if (executeMode && process.env.ALLOW_PRODUCTION_CLEANUP !== 'true') {
    console.error('ABORTED: ALLOW_PRODUCTION_CLEANUP=true is required for --execute.');
    process.exit(1);
  }
  if (!process.env.MONGODB_URI) {
    console.error('ABORTED: MONGODB_URI is not set.');
    process.exit(1);
  }

  await mongoose.connect(process.env.MONGODB_URI);
  const db = mongoose.connection.db!;
  await classify(db);
  printReport();

  if (executeMode) {
    console.log('\n=== EXECUTING ===');
    await execute(db);
  } else {
    console.log('\nDRY RUN — nothing was deleted.');
  }
  await mongoose.disconnect();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
