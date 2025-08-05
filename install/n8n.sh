#!/bin/bash

info "Setting up n8n..."

# Pull the n8n Docker image
docker pull n8nio/n8n

# Create data directory for persistence
mkdir -p ~/.n8n

# Initialize and start the container
info "Starting n8n container..."
docker run -d --name n8n -p 5678:5678 -v ~/.n8n:/home/node/.n8n n8nio/n8n

info "n8n setup complete!"
info "Access n8n at: http://localhost:5678"
info "To stop: docker stop n8n"
info "To restart: docker start n8n"
