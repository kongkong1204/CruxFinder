// src/routes/analysis.js

import { Router } from 'express';
import { createRequire } from 'module';
import { authenticate } from '../middlewares/auth.js';
import { upload } from '../middlewares/upload.js';
import { buildTaggedProblemJson, parseRoboflowHolds } from '../utils/holdJsonParser.js';
import { findPath } from '../utils/pathFinder.js';
import prisma from '../lib/prisma.js';
import fs from 'fs';

const require = createRequire(import.meta.url);
const axios = require('axios');

const router = Router();

// 이미지 업로드 + Roboflow 분석
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
      // 개발 모드: 더미 홀드 반환 (픽셀 좌표)
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
          `https://serverless.roboflow.com/${modelId}/${version}`,
          imageBase64,
          {
            params: { api_key: apiKey },
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          }
      );

      const { image, predictions } = roboflowRes.data;
      imageWidth = image.width;
      imageHeight = image.height;

      // parseRoboflowHolds로 파싱 (픽셀 좌표 그대로 유지)
      holds = parseRoboflowHolds({ predictions }, imageWidth, imageHeight);
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

// 태그 저장 + 최종 데이터셋 생성
router.post('/tag', authenticate, async (req, res) => {
  try {
    const { routeId, holds, wallHeight, wallTags } = req.body;

    // routeId로 이미지 크기 조회
    const route = await prisma.climbingRoute.findUnique({
      where: { id: Number(routeId) },
    });

    if (!route) {
      return res.status(404).json({ message: '분석 결과를 찾을 수 없습니다.' });
    }

    if (route.userId !== req.user.id) {
      return res.status(403).json({ message: '권한이 없습니다.' });
    }

    // 사용자 신체정보 조회
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: {
        height: true,
        weight: true,
        armReach: true,
        inseam: true,
      },
    });

    // 픽셀 좌표 → 정규화 좌표 변환
    const wallHeightCm = parseInt(wallHeight) || null;

    const normalizedHolds = holds.map((hold) => ({
      ...hold,
      x: hold.x / route.imageWidth,
      y: hold.y / route.imageHeight,
      width: hold.width / route.imageWidth,
      height: hold.height / route.imageHeight,
    }));

    const result = buildTaggedProblemJson({
      wall: {
        heightCm: wallHeightCm,
        imageWidth: route.imageWidth,
        imageHeight: route.imageHeight,
        angle: wallTags,
      },
      user: {
        heightCm: user?.height ?? null,
        armReachCm: user?.armReach ?? null,
        inseamCm: user?.inseam ?? null,
        weightKg: user?.weight ?? null,
      },
      holds: normalizedHolds,
    });

    if (!result.ok) {
      return res.status(400).json({ message: '데이터 검증 실패', errors: result.errors });
    }
    console.log('최종 데이터셋:', JSON.stringify(result.data, null, 2));
    // 최종 데이터셋으로 바로 경로 탐색
    // findPath가 wall에 내부 scale을 주입하므로 복사본을 넘겨 응답 원본 보호
    const solution = findPath({
      wall: { ...result.data.wall },
      user: result.data.user,
      holds: result.data.holds,
    });

    res.json({ ok: true, data: result.data, solution });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '서버 오류' });
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

// ── 개발용: 최종 데이터셋을 그대로 받아 findPath만 실행 (토큰 불필요) ──
router.post('/solve-test', (req, res) => {
  try {
    const { wall, user, holds } = req.body;
    if (!wall || !user || !Array.isArray(holds)) {
      return res.status(400).json({ message: 'wall, user, holds가 필요합니다.' });
    }
    // findPath가 wall에 내부 scale을 주입하므로 복사본 전달
    const solution = findPath({ wall: { ...wall }, user, holds });
    res.json({ solution });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '경로 탐색 중 오류', error: String(err) });
  }
});

export default router;