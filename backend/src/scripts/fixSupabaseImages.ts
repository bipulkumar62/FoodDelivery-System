import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

const supabaseUrl = 'https://yfpauoqjefpnnlplcevf.supabase.co';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

if (!supabaseServiceKey) {
  console.error('SUPABASE_SERVICE_ROLE_KEY not set in .env');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: { autoRefreshToken: false, persistSession: false }
});

async function makeBucketPublic() {
  try {
    // Try to update bucket to public
    const { data, error } = await supabase.storage.updateBucket('images', {
      public: true
    });

    if (error) {
      console.error('Error making bucket public:', error);
      
      // Alternative: generate new signed URLs with long expiry
      console.log('Generating new signed URLs with 10-year expiry...');
      
      // We'd need to get all objects and regenerate URLs
      // For now, let's just check what files exist
      const { data: files, error: listError } = await supabase.storage
        .from('images')
        .list('pawan biryani images', { limit: 100 });

      if (listError) {
        console.error('List error:', listError);
      } else {
        console.log('Files in bucket:', files);
        
        // Generate signed URLs for each file
        for (const file of files) {
          const { data: signedUrlData, error: signError } = await supabase.storage
            .from('images')
            .createSignedUrl(`pawan biryani images/${file.name}`, 60 * 60 * 24 * 365 * 10); // 10 years

          if (signError) {
            console.error(`Error signing ${file.name}:`, signError);
          } else {
            console.log(`${file.name} => ${signedUrlData.signedUrl}`);
          }
        }
      }
    } else {
      console.log('Bucket made public successfully!');
      console.log('New public URL format: https://yfpauoqjefpnnlplcevf.supabase.co/storage/v1/object/public/images/...');
    }
  } catch (err) {
    console.error('Unexpected error:', err);
  }
}

makeBucketPublic();