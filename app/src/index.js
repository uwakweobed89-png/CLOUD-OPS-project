const express = require('express');
const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');
const { Pool } = require('pg');

const app = express();
app.disable('x-powered-by');
app.use(express.json());

let dbPool = null;
let dbConnected = false;

async function initDatabase() {
    const secretArn = process.env.DB_SECRET_ARN;
    if (!secretArn) {
        console.log('DB_SECRET_ARN not set — running without database');
        return;
    }

    try {
        const smClient = new SecretsManagerClient({ region: process.env.AWS_REGION || 'us-east-1' });
        const response = await smClient.send(new GetSecretValueCommand({ SecretId: secretArn }));
        const secret = JSON.parse(response.SecretString);

        dbPool = new Pool({
            host: secret.host,
            port: secret.port,
            database: secret.dbname,
            user: secret.username,
            password: secret.password,
            ssl: { rejectUnauthorized: false },
            max: 10,
            idleTimeoutMillis: 30000,
            connectionTimeoutMillis: 5000,
        });

        await dbPool.query('SELECT 1');
        dbConnected = true;
        console.log('Database connected successfully');
    } catch (err) {
        console.error('Database connection failed:', err.message);
    }
}

async function checkDatabase() {
    if (!dbPool) {
        return { connected: false, message: 'DB_SECRET_ARN not configured' };
    }
    try {
        const start = Date.now();
        const result = await dbPool.query('SELECT NOW() AS current_time');
        return {
            connected: true,
            latency_ms: Date.now() - start,
            db_time: result.rows[0].current_time
        };
    } catch (err) {
        return { connected: false, message: err.message };
    }
}

app.get('/', (req, res) => {
    res.json({
        service: 'cloudops-api',
        version: '1.0.0',
        endpoints: ['/health', '/api/v1/data', '/api/v1/health-detailed']
    });
});

app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'development'
    });
});

app.get('/api/v1/data', (req, res) => {
    res.json({
        service: 'cloudops-api',
        version: '1.0.0',
        status: 'running',
        database: dbConnected ? 'connected' : 'unavailable'
    });
});

app.get('/api/v1/health-detailed', async (req, res) => {
    const db = await checkDatabase();
    const overall = db.connected ? 'healthy' : 'degraded';

    res.status(db.connected ? 200 : 503).json({
        status: overall,
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'development',
        database: db,
        secrets_manager: {
            configured: !!process.env.DB_SECRET_ARN,
            secret_arn: process.env.DB_SECRET_ARN || 'not set'
        }
    });
});

const PORT = process.env.PORT || 8080;

initDatabase().then(() => {
    app.listen(PORT, () => {
        console.log(`CloudOps API running on port ${PORT}`);
    });
});
