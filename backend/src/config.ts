export const env = {
  DB_HOST: process.env.DB_HOST || 'localhost',
  DB_PORT: parseInt(process.env.DB_PORT || '5432', 10),
  DB_DATABASE: process.env.DB_DATABASE || 'trading_bot',
  DB_USERNAME: process.env.DB_USERNAME || 'postgres',
  DB_PASSWORD: process.env.DB_PASSWORD || 'admin',
  PORT: parseInt(process.env.PORT || '3000', 10),
};
