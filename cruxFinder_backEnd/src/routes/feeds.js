import { Router } from 'express';
import prisma from '../lib/prisma.js';
import { authenticate } from '../middlewares/auth.js';

const router = Router();

// 피드 목록 조회
router.get('/', authenticate, async (req, res) => {
  try {
    const feeds = await prisma.feed.findMany({
      where: { userId: req.user.id },
      orderBy: { climbedAt: 'desc' },
    });
    res.json(feeds);
  } catch (err) {
    res.status(500).json({ message: '서버 오류' });
  }
});

// 피드 생성
router.post('/', authenticate, async (req, res) => {
  try {
    const { memo, climbedAt, vGrade, myDifficulty } = req.body;
    if (!memo || !climbedAt || !vGrade || !myDifficulty)
      return res.status(400).json({ message: '필수 항목을 입력해주세요.' });

    const feed = await prisma.feed.create({
      data: {
        memo,
        climbedAt: new Date(climbedAt),
        vGrade,
        myDifficulty,
        userId: req.user.id,
      },
    });
    res.status(201).json(feed);
  } catch (err) {
    res.status(500).json({ message: '서버 오류' });
  }
});

// 피드 수정
router.patch('/:id', authenticate, async (req, res) => {
  try {
    const feedId = Number(req.params.id);
    const { memo, climbedAt, vGrade, myDifficulty } = req.body;

    const feed = await prisma.feed.findUnique({ where: { id: feedId } });
    if (!feed) return res.status(404).json({ message: '피드를 찾을 수 없습니다.' });
    if (feed.userId !== req.user.id) return res.status(403).json({ message: '권한이 없습니다.' });

    const updated = await prisma.feed.update({
      where: { id: feedId },
      data: {
        ...(memo !== undefined && { memo }),
        ...(climbedAt !== undefined && { climbedAt: new Date(climbedAt) }),
        ...(vGrade !== undefined && { vGrade }),
        ...(myDifficulty !== undefined && { myDifficulty }),
      },
    });
    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: '서버 오류' });
  }
});

// 피드 삭제
router.delete('/:id', authenticate, async (req, res) => {
  try {
    const feedId = Number(req.params.id);

    const feed = await prisma.feed.findUnique({ where: { id: feedId } });
    if (!feed) return res.status(404).json({ message: '피드를 찾을 수 없습니다.' });
    if (feed.userId !== req.user.id) return res.status(403).json({ message: '권한이 없습니다.' });

    await prisma.feed.delete({ where: { id: feedId } });
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ message: '서버 오류' });
  }
});

export default router;
