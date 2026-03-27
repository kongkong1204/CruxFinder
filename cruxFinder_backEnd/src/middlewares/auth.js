import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const jwt = require('jsonwebtoken');

export function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : null;

  if (!token) {
    // 브라우저 요청이면 로그인 페이지로
    if (req.accepts('html')) return res.redirect('/login.html');
    return res.status(401).json({ message: '로그인이 필요합니다.' });
  }

  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch {
    if (req.accepts('html')) {
      return res.redirect('/login.html');
    }
    return res.status(401).json({ message: '유효하지 않은 토큰입니다.' });
  }
}
