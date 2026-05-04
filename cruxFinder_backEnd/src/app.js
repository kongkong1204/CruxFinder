import express from 'express';
import healthRouter from './routes/health.js';
import usersRouter from './routes/users.js';
import authRouter from './routes/auth.js';
import { authenticate } from './middlewares/auth.js';
import mypageRouter from './routes/mypage.js';


const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static('public'));

app.use('/health', healthRouter);
app.use('/users', usersRouter);
app.use('/auth', authRouter);
app.use('/api/mypage', mypageRouter);

app.get('/mypage', (req, res) => {
  res.sendFile('mypage.html', { root: 'public' });
});

export default app;
