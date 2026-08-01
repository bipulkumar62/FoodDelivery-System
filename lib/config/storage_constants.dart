/// Client-safe Supabase Storage configuration.
///
/// IMPORTANT: Only the publishable (anon) key belongs here. It is designed
/// to be embedded in client apps. NEVER place the service_role key here.
class StorageConstants {
  static const String supabaseUrl = 'https://yfpauoqjefpnnlplcevf.supabase.co';

  /// Publishable anon key for project yfpauoqjefpnnlplcevf.
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmcGF1b3FqZWZwbm5scGxjZXZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ2ODkzMjQsImV4cCI6MjEwMDI2NTMyNH0.ADj51tYG-jypH8ZeGYwO0uLV5Pz_GxdU-B-t0DntL-k';

  /// Existing public bucket that stores Pawan Biryani food images.
  static const String bucketName = 'pawan';

  /// Folder inside the bucket used for admin-uploaded menu images.
  static const String uploadFolder = 'menu';
}
