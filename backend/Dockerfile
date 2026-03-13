FROM node:20-alpine

WORKDIR /app

# Install dependencies first for better layer caching
COPY package.json package-lock.json ./
RUN npm install

# Copy Prisma schema and generate client
COPY prisma.config.ts ./
COPY prisma ./prisma
RUN npx prisma generate

# Copy source files and build
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# Expose port
EXPOSE 3000

# Start the application in production after applying migrations
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/index.js"]
