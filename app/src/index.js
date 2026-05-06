const express = require('express');
const app = express();

app.use(express.json());

// Health check endpoint ECS will use to determine if the container is healthy
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'development'
    });
});

// Main API endpoint
app.get('/api/v1/data', (req, res) => {
    res.json({ 
        service : 'cloudops-api',
        version: '1.0.0',
        status: 'running'
    });
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
    console.log(`CloudOps API is running on port ${PORT}`);
}); 
