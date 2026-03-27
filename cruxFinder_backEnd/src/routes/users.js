import { Router } from 'express';
import { createRequire } from 'module';
import prisma from '../lib/prisma.js';
import { authenticate } from '../middlewares/auth.js';

const require = createRequire(import.meta.url);
const bcrypt = require('bcryptjs');

const router = Router();

// 내 정보
router.get('/me', authenticate, async (req, res) => {
  try {
    const user = await prisma.user.findUnique({ where: { id: req.user.id } });
    if (!user) return res.status(404).json({ message: '사용자를 찾을 수 없습니다.' });
    res.json({ id: user.id, email: user.email, name: user.name });
  } catch (err) {
    res.status(500).json({ message: '서버 오류' });
  }
});

// 비밀번호 재확인 (정보 수정 전)
router.post('/verify-password', authenticate, async (req, res) => {
  try {
    const { password } = req.body;
    if (!password) return res.status(400).json({ message: '비밀번호를 입력해주세요.' });

    const user = await prisma.user.findUnique({ where: { id: req.user.id } });
    if (!user) return res.status(404).json({ message: '사용자를 찾을 수 없습니다.' });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(401).json({ message: '비밀번호가 일치하지 않습니다.' });

    res.json({ verified: true });
  } catch (err) {
    res.status(500).json({ message: '서버 오류' });
  }
});

// 이메일/비밀번호 수정
router.patch('/me', authenticate, async (req, res) => {
  try {
    const { email, newPassword } = req.body;
    if (!email && !newPassword)
      return res.status(400).json({ message: '수정할 항목을 입력해주세요.' });

    const data = {};
    if (email) data.email = email;
    if (newPassword) {
      if (!/^(?=.*[A-Za-z])(?=.*\d).+$/.test(newPassword))
        return res.status(400).json({ message: '비밀번호는 영문과 숫자를 모두 포함해야 합니다.' });
      data.password = await bcrypt.hash(newPassword, 10);
    }

    const updated = await prisma.user.update({ where: { id: req.user.id }, data });
    res.json({ id: updated.id, email: updated.email, name: updated.name });
  } catch (err) {
    if (err.code === 'P2002') return res.status(409).json({ message: '이미 사용 중인 이메일입니다.' });
    if (err.code === 'P2025') return res.status(404).json({ message: '사용자를 찾을 수 없습니다.' });
    res.status(500).json({ message: '서버 오류' });
  }
});

router.get('/', async (req, res) => {
  try {
    const users = await prisma.user.findMany();
    res.json(users);
  } catch (err) {
    res.status(500).json({ message: '서버 오류' });
  }
});

router.post('/', async (req, res) => {
  try {
    const { email, name, password } = req.body;
    if (!email) return res.status(400).json({ message: '이메일은 필수입니다.' });
    if (!password) return res.status(400).json({ message: '비밀번호는 필수입니다.' });
    if (!/^(?=.*[A-Za-z])(?=.*\d).+$/.test(password))
      return res.status(400).json({ message: '비밀번호는 영문과 숫자를 모두 포함해야 합니다.' });
    const hashed = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({ data: { email, name, password: hashed } });
    res.status(201).json({ id: user.id, email: user.email, name: user.name });
  } catch (err) {
    if (err.code === 'P2002') return res.status(409).json({ message: '이미 사용 중인 이메일입니다.' });
    res.status(500).json({ message: '서버 오류' });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const user = await prisma.user.findUnique({ where: { id: Number(req.params.id) } });
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: '서버 오류' });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const { email, name } = req.body;
    const user = await prisma.user.update({
      where: { id: Number(req.params.id) },
      data: { email, name },
    });
    res.json(user);
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ message: 'User not found' });
    res.status(500).json({ message: '서버 오류' });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    await prisma.user.delete({ where: { id: Number(req.params.id) } });
    res.status(204).send();
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ message: 'User not found' });
    res.status(500).json({ message: '서버 오류' });
  }
});

export default router;
