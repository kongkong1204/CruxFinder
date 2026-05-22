import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import healthRouter from './routes/health.js';
import usersRouter from './routes/users.js';
import authRouter from './routes/auth.js';
import feedsRouter from './routes/feeds.js';
import analysisRouter from './routes/analysis.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static('public'));
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

app.use('/health', healthRouter);
app.use('/auth', authRouter);
app.use('/users', usersRouter);
app.use('/feeds', feedsRouter);
app.use('/analysis', analysisRouter);

export default app;
