import { Router } from 'express';
import fs from 'fs';
import prisma from '../lib/prisma.js';
import { authenticate } from '../middlewares/auth.js';
import { upload, deleteFileByUrl } from '../middlewares/upload.js';

const router = Router();

function imageUrlFromReq(req) {
  return `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;
}

// 피드 목록 조회
router.get('/', authenticate, async (req, res) => {
  try {
    const feeds = await prisma.feed.findMany({
      where: { userId: req.user.id },
      orderBy: { climbedAt: 'desc' },
    });
    res.json(feeds);
  } catch {
    res.status(500).json({ message: '서버 오류' });
  }
});

// 피드 생성
router.post('/', authenticate, upload.single('image'), async (req, res) => {
  const rollback = () => req.file && fs.unlink(req.file.path, () => {});
  try {
    const { memo, climbedAt, vGrade, myDifficulty } = req.body;
    if (!memo || !climbedAt || !vGrade || !myDifficulty) {
      rollback();
      return res.status(400).json({ message: '필수 항목을 입력해주세요.' });
    }

    const feed = await prisma.feed.create({
      data: {
        memo,
        climbedAt: new Date(climbedAt),
        vGrade,
        myDifficulty,
        imageUrl: req.file ? imageUrlFromReq(req) : null,
        userId: req.user.id,
      },
    });
    res.status(201).json(feed);
  } catch {
    rollback();
    res.status(500).json({ message: '서버 오류' });
  }
});

// 피드 수정
router.patch('/:id', authenticate, upload.single('image'), async (req, res) => {
  const rollback = () => req.file && fs.unlink(req.file.path, () => {});
  try {
    const feedId = Number(req.params.id);
    const { memo, climbedAt, vGrade, myDifficulty, removeImage } = req.body;

    const feed = await prisma.feed.findUnique({ where: { id: feedId } });
    if (!feed) {
      rollback();
      return res.status(404).json({ message: '피드를 찾을 수 없습니다.' });
    }
    if (feed.userId !== req.user.id) {
      rollback();
      return res.status(403).json({ message: '권한이 없습니다.' });
    }

    let imageUpdate = {};
    if (req.file) {
      if (feed.imageUrl) deleteFileByUrl(feed.imageUrl);
      imageUpdate = { imageUrl: imageUrlFromReq(req) };
    } else if (removeImage === 'true' && feed.imageUrl) {
      deleteFileByUrl(feed.imageUrl);
      imageUpdate = { imageUrl: null };
    }

    const updated = await prisma.feed.update({
      where: { id: feedId },
      data: {
        ...(memo !== undefined && { memo }),
        ...(climbedAt !== undefined && { climbedAt: new Date(climbedAt) }),
        ...(vGrade !== undefined && { vGrade }),
        ...(myDifficulty !== undefined && { myDifficulty }),
        ...imageUpdate,
      },
    });
    res.json(updated);
  } catch {
    rollback();
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

    if (feed.imageUrl) deleteFileByUrl(feed.imageUrl);
    await prisma.feed.delete({ where: { id: feedId } });
    res.status(204).send();
  } catch {
    res.status(500).json({ message: '서버 오류' });
  }
});

export default router;
