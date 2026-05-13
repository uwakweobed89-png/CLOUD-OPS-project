# Use an official Node.js runtime as a parent image
FROM node:22-alpine AS builder

# Set the working directory in the container
WORKDIR /app
# Copy package.json and package-lock.json to the working directory
COPY package*.json ./
# Install all dependencies
RUN npm ci --omit=dev
# Copy the rest of the application code to the working directory
COPY src ./src

# runtime image
FROM node:22-alpine AS runtime

#security best practices as non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy only the necessary files from the builder stage
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/src ./src
COPY package.json ./

#switch to non-root user
USER appuser

# Expose the port the app runs on
EXPOSE 8080

#health check
HEALTHCHECK --interval=30s --timeout=3s  --retries=3 \
    CMD wget -q0- http://localhost:8080/health || exit 1

# Command to run the application
CMD ["node", "src/index.js"]
