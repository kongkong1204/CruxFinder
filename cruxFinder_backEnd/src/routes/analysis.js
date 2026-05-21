import { Router } from 'express';
import { createRequire } from 'module';
import { authenticate } from '../middlewares/auth.js';
import { upload } from '../middlewares/upload.js';
import prisma from '../lib/prisma.js';
import fs from 'fs';

const require = createRequire(import.meta.url);
const axios = require('axios');

const router = Router();

router.post('/upload', authenticate, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: '이미지를 업로드해주세요.' });
    }

    const imageUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;

    const modelId = process.env.ROBOFLOW_MODEL_ID;
    const version = process.env.ROBOFLOW_VERSION || '1';
    const apiKey = process.env.ROBOFLOW_API_KEY;

    let holds, imageWidth, imageHeight;

    if (!modelId || !apiKey) {
      // 개발 모드: 더미 홀드 반환
      imageWidth = 1080;
      imageHeight = 1920;
      holds = [
        { id: '1', x: 200, y: 400, width: 80, height: 80, confidence: 0.95 },
        { id: '2', x: 500, y: 700, width: 70, height: 90, confidence: 0.88 },
        { id: '3', x: 350, y: 1100, width: 90, height: 75, confidence: 0.91 },
        { id: '4', x: 150, y: 1400, width: 85, height: 85, confidence: 0.76 },
      ];
    } else {
      const imageBuffer = fs.readFileSync(req.file.path);
      const imageBase64 = imageBuffer.toString('base64');

      const roboflowRes = await axios.post(
        `https://detect.roboflow.com/${modelId}/${version}`,
        imageBase64,
        {
          params: { api_key: apiKey },
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        }
      );

      const { image, predictions } = roboflowRes.data;
      imageWidth = image.width;
      imageHeight = image.height;
      holds = predictions.map((p, i) => ({
        id: p.detection_id || String(i),
        x: p.x,
        y: p.y,
        width: p.width,
        height: p.height,
        confidence: p.confidence,
      }));
    }

    const route = await prisma.climbingRoute.create({
      data: {
        userId: req.user.id,
        imageUrl,
        imageWidth,
        imageHeight,
        holds,
      },
    });

    res.json({
      routeId: route.id,
      imageUrl,
      imageWidth,
      imageHeight,
      holds,
      dev: !modelId || !apiKey,
    });
  } catch (err) {
    if (req.file) fs.unlink(req.file.path, () => {});
    console.error(err);
    res.status(500).json({ message: '분석 중 오류가 발생했습니다.' });
  }
});

// 분석 결과 조회
router.get('/routes', authenticate, async (req, res) => {
  try {
    const routes = await prisma.climbingRoute.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' },
      select: { id: true, imageUrl: true, imageWidth: true, imageHeight: true, createdAt: true },
    });
    res.json(routes);
  } catch (err) {
    res.status(500).json({ message: '서버 오류' });
  }
});

// 특정 분석 결과 조회
router.get('/routes/:id', authenticate, async (req, res) => {
  try {
    const route = await prisma.climbingRoute.findUnique({
      where: { id: Number(req.params.id) },
    });
    if (!route) return res.status(404).json({ message: '분석 결과를 찾을 수 없습니다.' });
    if (route.userId !== req.user.id) return res.status(403).json({ message: '권한이 없습니다.' });
    res.json(route);
  } catch (err) {
    res.status(500).json({ message: '서버 오류' });
  }
});

export default router;
