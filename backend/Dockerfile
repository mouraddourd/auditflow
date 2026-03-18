FROM node:20-alpine

# Install postgresql-client for database checks in entrypoint script
RUN apk add --no-cache postgresql-client

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

# Copy startup script
COPY docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

# Start the application with migration handling
CMD ["./docker-entrypoint.sh"]
