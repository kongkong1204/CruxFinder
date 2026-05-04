import { Router } from 'express';
import { createRequire } from 'module';
import prisma from '../lib/prisma.js';

const require = createRequire(import.meta.url);
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const router = Router();

const codes = {};

// 로그인 → JWT 발급
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password)
      return res.status(400).json({ message: '이메일과 비밀번호를 입력해주세요.' });

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user)
      return res.status(401).json({ message: '이메일 또는 비밀번호가 올바르지 않습니다.' });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch)
      return res.status(401).json({ message: '이메일 또는 비밀번호가 올바르지 않습니다.' });

    const token = jwt.sign(
      { id: user.id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({ token, user: { id: user.id, email: user.email, name: user.name } });
  } catch (err) {
    res.status(500).json({ message: '서버 오류' });
  }
});

// 비밀번호 재설정 요청 (이메일 확인)
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email)
      return res.status(400).json({ message: '이메일을 입력해주세요.' });

    const user = await prisma.user.findUnique({ where: { email } });

    if (!user)
      return res.status(404).json({ message: '해당 이메일은 등록되어있지 않습니다.' });

    // 인증 코드 생성 (6자리)
    const code = Math.floor(100000 + Math.random() * 900000).toString();

    codes[email] = {
      code,
      expire: Date.now() + 60000
    };

    console.log(`인증코드 (${email}):`, code);

    res.json({ message: '인증코드가 전송되었습니다.' });
  } catch (err) {
    res.status(500).json({ message: '서버 오류' });
  }
});

// 인증코드 확인
router.post('/verify-code', (req, res) => {
  const { email, code } = req.body;
  const saved = codes[email];

  if (!saved) {
    return res.status(400).json({ message: '인증번호가 존재하지 않습니다.' });
  }

  if (Date.now() > saved.expire) {
    delete codes[email];
    return res.status(400).json({ message: '인증번호가 만료되었습니다.' });
  }

  if (saved.code !== code) {
    return res.status(400).json({ message: '인증번호가 올바르지 않습니다.' });
  }

  res.json({ message: '인증 성공' });
});

// 비밀번호 변경
router.post('/reset-password', async (req, res) => {
  try {
    const { email, newPassword } = req.body;

    if (!newPassword)
      return res.status(400).json({ message: '새 비밀번호를 입력해주세요.' });

    if (!/^(?=.*[A-Za-z])(?=.*\d).+$/.test(newPassword))
      return res.status(400).json({ message: '비밀번호는 영문과 숫자를 모두 포함해야 합니다.' });

    const hashed = await bcrypt.hash(newPassword, 10);

    await prisma.user.update({
      where: { email },
      data: { password: hashed }
    });

    // 사용한 코드 삭제
    delete codes[email];

    res.json({ message: '비밀번호 변경 완료' });
  } catch (err) {
    res.status(500).json({ message: '서버 오류' });
  }
});

export default router;