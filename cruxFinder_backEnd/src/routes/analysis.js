import { Router } from 'express';
import { createRequire } from 'module';
import { authenticate } from '../middlewares/auth.js';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';

const require = createRequire(import.meta.url);
const multer = require('multer');
const axios = require('axios');

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const uploadDir = path.join(__dirname, '../../uploads');

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `${Date.now()}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 20 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (!file.mimetype.startsWith('image/')) {
      return cb(new Error('이미지 파일만 업로드 가능합니다.'));
    }
    cb(null, true);
  },
});

const router = Router();

router.post('/upload', authenticate, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: '이미지를 업로드해주세요.' });
    }

    const imageBuffer = fs.readFileSync(req.file.path);
    const imageBase64 = imageBuffer.toString('base64');

    const modelId = process.env.ROBOFLOW_MODEL_ID;
    const version = process.env.ROBOFLOW_VERSION || '1';
    const apiKey = process.env.ROBOFLOW_API_KEY;

    const imageUrl = `http://localhost:${process.env.PORT || 3000}/uploads/${req.file.filename}`;

    if (!modelId || !apiKey) {
      // Roboflow 미설정 시 더미 데이터 반환 (개발용)
      return res.json({
        imageUrl,
        imageWidth: 1080,
        imageHeight: 1920,
        holds: [
          { id: '1', x: 200, y: 400, width: 80, height: 80, confidence: 0.95 },
          { id: '2', x: 500, y: 700, width: 70, height: 90, confidence: 0.88 },
          { id: '3', x: 350, y: 1100, width: 90, height: 75, confidence: 0.91 },
          { id: '4', x: 150, y: 1400, width: 85, height: 85, confidence: 0.76 },
        ],
        dev: true,
      });
    }

    const roboflowRes = await axios.post(
      `https://detect.roboflow.com/${modelId}/${version}`,
      imageBase64,
      {
        params: { api_key: apiKey },
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      }
    );

    const { image, predictions } = roboflowRes.data;

    const holds = predictions.map((p, i) => ({
      id: p.detection_id || String(i),
      x: p.x,
      y: p.y,
      width: p.width,
      height: p.height,
      confidence: p.confidence,
    }));

    res.json({
      imageUrl,
      imageWidth: image.width,
      imageHeight: image.height,
      holds,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: '분석 중 오류가 발생했습니다.' });
  }
});

export default router;
