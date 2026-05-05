import { Router } from 'express';
import { createRequire } from 'module';
import prisma from '../lib/prisma.js';
import { authenticate } from '../middlewares/auth.js';

const require = createRequire(import.meta.url);
const bcrypt = require('bcryptjs');

const router = Router();

// 닉네임 중복 확인
router.get('/check-nickname', async (req, res) => {
  try {
    const { nickname } = req.query;
    if (!nickname) return res.status(400).json({ message: '닉네임을 입력해주세요.' });

    const existing = await prisma.user.findUnique({ where: { nickname } });
    res.json({ available: !existing });
  } catch (err) {
    res.status(500).json({ message: '서버 오류' });
  }
});

// 내 정보 조회
router.get('/me', authenticate, async (req, res) => {
  try {
    const user = await prisma.user.findUnique({ where: { id: req.user.id } });
    if (!user) return res.status(404).json({ message: '사용자를 찾을 수 없습니다.' });
    res.json({
      id: user.id,
      email: user.email,
      nickname: user.nickname,
      height: user.height,
      weight: user.weight,
      armReach: user.armReach,
    });
  } catch (err) {
    res.status(500).json({ message: '서버 오류' });
  }
});

// 비밀번호 재확인
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

// 계정 정보 수정 (닉네임, 비밀번호)
router.patch('/me', authenticate, async (req, res) => {
  try {
    const { nickname, newPassword } = req.body;
    if (!nickname && !newPassword)
      return res.status(400).json({ message: '수정할 항목을 입력해주세요.' });

    const data = {};
    if (nickname) data.nickname = nickname;
    if (newPassword) {
      if (!/^(?=.*[A-Za-z])(?=.*\d).+$/.test(newPassword))
        return res.status(400).json({ message: '비밀번호는 영문과 숫자를 모두 포함해야 합니다.' });
      data.password = await bcrypt.hash(newPassword, 10);
    }

    const updated = await prisma.user.update({ where: { id: req.user.id }, data });
    res.json({ id: updated.id, email: updated.email, nickname: updated.nickname });
  } catch (err) {
    if (err.code === 'P2002') return res.status(409).json({ message: '이미 사용 중인 닉네임입니다.' });
    if (err.code === 'P2025') return res.status(404).json({ message: '사용자를 찾을 수 없습니다.' });
    res.status(500).json({ message: '서버 오류' });
  }
});

// 신체 정보 수정
router.patch('/me/body', authenticate, async (req, res) => {
  try {
    const { height, weight, armReach } = req.body;
    if (height === undefined && weight === undefined && armReach === undefined)
      return res.status(400).json({ message: '수정할 항목을 입력해주세요.' });

    const data = {};
    if (height !== undefined) data.height = parseFloat(height);
    if (weight !== undefined) data.weight = parseFloat(weight);
    if (armReach !== undefined) data.armReach = parseFloat(armReach);

    const updated = await prisma.user.update({ where: { id: req.user.id }, data });
    res.json({
      height: updated.height,
      weight: updated.weight,
      armReach: updated.armReach,
    });
  } catch (err) {
    res.status(500).json({ message: '서버 오류' });
  }
});

// 회원가입
router.post('/', async (req, res) => {
  try {
    const { email, nickname, password } = req.body;
    if (!email) return res.status(400).json({ message: '이메일은 필수입니다.' });
    if (!nickname) return res.status(400).json({ message: '닉네임은 필수입니다.' });
    if (!password) return res.status(400).json({ message: '비밀번호는 필수입니다.' });

    if (!/^(?=.*[A-Za-z])(?=.*\d).+$/.test(password))
      return res.status(400).json({ message: '비밀번호는 영문과 숫자를 모두 포함해야 합니다.' });

    const hashed = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({
      data: { email, nickname, password: hashed, isEmailVerified: true },
    });
    res.status(201).json({ id: user.id, email: user.email, nickname: user.nickname });
  } catch (err) {
    if (err.code === 'P2002') {
      const field = err.meta?.target?.includes('email') ? '이메일' : '닉네임';
      return res.status(409).json({ message: `이미 사용 중인 ${field}입니다.` });
    }
    res.status(500).json({ message: '서버 오류' });
  }
});

export default router;
