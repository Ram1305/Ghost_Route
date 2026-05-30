import mongoose from 'mongoose';

/**
 * Build MongoDB URI from .env.
 * Uses MONGODB_URI if set; otherwise builds from MONGODB_HOST, MONGODB_PORT, MONGODB_DATABASE, etc.
 */
function getMongoUri() {
  if (process.env.MONGODB_URI) {
    return process.env.MONGODB_URI;
  }
  const host = process.env.MONGODB_HOST || 'localhost';
  const port = process.env.MONGODB_PORT || '27017';
  const database = process.env.MONGODB_DATABASE || 'ghost_route';
  const user = process.env.MONGODB_USER;
  const password = process.env.MONGODB_PASSWORD;
  const auth = user && password ? `${encodeURIComponent(user)}:${encodeURIComponent(password)}@` : '';
  return `mongodb://${auth}${host}:${port}/${database}`;
}

/**
 * Connect to MongoDB using .env configuration (port and URI).
 */
export async function connectDB() {
  const uri = getMongoUri();
  try {
    await mongoose.connect(uri);
    console.log('MongoDB connected');
  } catch (err) {
    console.error('MongoDB connection error:', err.message);
    throw err;
  }
}

export default connectDB;
