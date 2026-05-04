import { Router } from 'express';
import { createRequire } from 'module';
import prisma from '../lib/prisma.js';
import { authenticate } from '../middlewares/auth.js';

const require = createRequire(import.meta.url);
const bcrypt = require('bcryptjs');

const router = Router();

router.get('/account', authenticate, async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      include: { profile: true },
    });

    if (!user) {
      return res.status(404).json({ message: '사용자를 찾을 수 없습니다.' });
    }

    res.json({
      id: user.id,
      email: user.email,
      name: user.name,
      profile: user.profile,
    });
  } catch (err) {
    res.status(500).json({ message: '서버 오류' });
  }
});

router.patch('/account', authenticate, async (req, res) => {
  try {
    const { name, email, currentPassword, newPassword } = req.body;

    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
    });

    if (!user) {
      return res.status(404).json({ message: '사용자를 찾을 수 없습니다.' });
    }

    const data = {};

    if (name !== undefined) data.name = name;

    if (email || newPassword) {
      if (!currentPassword) {
        return res.status(400).json({ message: '현재 비밀번호를 입력해주세요.' });
      }

      const isMatch = await bcrypt.compare(currentPassword, user.password);
      if (!isMatch) {
        return res.status(401).json({ message: '비밀번호가 일치하지 않습니다.' });
      }
    }

    if (email) data.email = email;

    if (newPassword) {
      if (!/^(?=.*[A-Za-z])(?=.*\d).+$/.test(newPassword)) {
        return res.status(400).json({ message: '비밀번호는 영문과 숫자를 모두 포함해야 합니다.' });
      }

      data.password = await bcrypt.hash(newPassword, 10);
    }

    const updated = await prisma.user.update({
      where: { id: req.user.id },
      data,
    });

    res.json({
      id: updated.id,
      email: updated.email,
      name: updated.name,
    });
  } catch (err) {
    if (err.code === 'P2002') {
      return res.status(409).json({ message: '이미 사용 중인 이메일입니다.' });
    }

    res.status(500).json({ message: '서버 오류' });
  }
});

router.patch('/profile', authenticate, async (req, res) => {
  try {
    const { heightCm, weightKg, armReachCm } = req.body;

    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
    });

    if (!user) {
      return res.status(404).json({ message: '사용자를 찾을 수 없습니다.' });
    }

    const profile = await prisma.userProfile.upsert({
      where: { userEmail: user.email },
      update: {
        heightCm: heightCm === undefined ? undefined : Number(heightCm),
        weightKg: weightKg === undefined ? undefined : Number(weightKg),
        armReachCm: armReachCm === undefined ? undefined : Number(armReachCm),
      },
      create: {
        userEmail: user.email,
        heightCm: heightCm === undefined ? null : Number(heightCm),
        weightKg: weightKg === undefined ? null : Number(weightKg),
        armReachCm: armReachCm === undefined ? null : Number(armReachCm),
      },
    });

    res.json(profile);
  } catch (err) {
    res.status(500).json({ message: '서버 오류' });
  }
});

router.delete('/account', authenticate, async (req, res) => {
  try {
    const { password } = req.body;

    if (!password) {
      return res.status(400).json({ message: '비밀번호를 입력해주세요.' });
    }

    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
    });

    if (!user) {
      return res.status(404).json({ message: '사용자를 찾을 수 없습니다.' });
    }

    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(401).json({ message: '비밀번호가 일치하지 않습니다.' });
    }

    await prisma.user.delete({
      where: { id: req.user.id },
    });

    res.json({ message: '계정이 삭제되었습니다.' });
  } catch (err) {
    res.status(500).json({ message: '서버 오류' });
  }
});


export default router;
