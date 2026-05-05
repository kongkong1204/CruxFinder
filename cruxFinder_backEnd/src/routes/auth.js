import { Router } from 'express';
import { createRequire } from 'module';
import prisma from '../lib/prisma.js';

const require = createRequire(import.meta.url);
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');

const router = Router();

const resetCodes = {};

function generateCode() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

function createTransporter() {
  if (process.env.SMTP_USER && process.env.SMTP_PASS) {
    return nodemailer.createTransport({
      service: 'gmail',
      auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
    });
  }
  return null;
}

// 회원가입용 이메일 인증 코드 발송
router.post('/send-code', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: '이메일을 입력해주세요.' });

    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) return res.status(409).json({ message: '이미 사용 중인 이메일입니다.' });

    const code = generateCode();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    await prisma.emailVerification.deleteMany({ where: { email } });
    await prisma.emailVerification.create({ data: { email, code, expiresAt } });

    const transporter = createTransporter();
    if (transporter) {
      await transporter.sendMail({
        from: process.env.SMTP_USER,
        to: email,
        subject: '[CruxFinder] 이메일 인증 코드',
        text: `인증 코드: ${code}\n5분 이내에 입력해주세요.`,
      });
      res.json({ message: '인증 코드가 이메일로 발송되었습니다.' });
    } else {
      res.json({ message: '인증 코드가 발송되었습니다. (개발 모드)', devCode: code });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '서버 오류' });
  }
});

// 회원가입용 이메일 인증 코드 검증
router.post('/verify-code', async (req, res) => {
  try {
    const { email, code } = req.body;
    if (!email || !code) return res.status(400).json({ message: '이메일과 코드를 입력해주세요.' });

    const record = await prisma.emailVerification.findFirst({
      where: { email },
      orderBy: { createdAt: 'desc' },
    });

    if (!record) return res.status(400).json({ message: '인증 코드를 먼저 요청해주세요.' });
    if (new Date() > record.expiresAt) return res.status(400).json({ message: '인증 코드가 만료되었습니다.' });
    if (record.code !== code) return res.status(400).json({ message: '인증 코드가 올바르지 않습니다.' });

    await prisma.emailVerification.deleteMany({ where: { email } });

    res.json({ verified: true });
  } catch (err) {
    res.status(500).json({ message: '서버 오류' });
  }
});

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

    res.json({
      token,
      user: { id: user.id, email: user.email, nickname: user.nickname },
    });
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

    const code = Math.floor(100000 + Math.random() * 900000).toString();

    resetCodes[email] = {
      code,
      expire: Date.now() + 60000
    };

    console.log(`비밀번호 재설정 인증코드 (${email}):`, code);

    res.json({ message: '인증코드가 전송되었습니다.' });
  } catch (err) {
    res.status(500).json({ message: '서버 오류' });
  }
});

// 비밀번호 재설정용 인증코드 확인
router.post('/verify-reset-code', (req, res) => {
  const { email, code } = req.body;
  const saved = resetCodes[email];

  if (!saved) {
    return res.status(400).json({ message: '인증번호가 존재하지 않습니다.' });
  }

  if (Date.now() > saved.expire) {
    delete resetCodes[email];
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

    delete resetCodes[email];

    res.json({ message: '비밀번호 변경 완료' });
  } catch (err) {
    res.status(500).json({ message: '서버 오류' });
  }
});

export default router;
