# Crux Finder

## 기술 스택
- **Runtime**: Node.js (ESM)
- **Framework**: Express
- **ORM**: Prisma v7 + `@prisma/adapter-mariadb` (MySQL 8.0 연결)
- **DB**: MySQL 8.0 (`crux_finder` 데이터베이스)
- **인증**: JWT (`jsonwebtoken`) + bcrypt 비밀번호 해싱 (`bcryptjs`)

---

## 프로젝트 구조

```
src/
├── server.js              # 서버 진입점
├── app.js                 # Express 앱, 라우터 등록
├── middlewares/
│   └── auth.js            # JWT 인증 미들웨어
├── lib/
│   └── prisma.js          # PrismaClient 초기화
└── routes/
    ├── health.js          # GET /health
    ├── users.js           # 유저 CRUD + 마이페이지 API
    └── auth.js            # POST /auth/login

public/
├── index.html             # 메인 페이지
├── signup.html            # 회원가입
├── login.html             # 로그인
├── mypage.html            # 마이페이지 (정보 조회/수정)
└── users.html             # 유저 목록

prisma/
├── schema.prisma          # DB 스키마
└── migrations/
```

---

## DB 스키마

```prisma
model User {
  id       Int     @id @default(autoincrement())
  email    String  @unique
  name     String?
  password String
}
```

---

## API 엔드포인트

| Method | Path | 인증 | 설명 |
|--------|------|------|------|
| GET | `/health` | - | 서버 상태 확인 |
| POST | `/users` | - | 회원가입 |
| GET | `/users` | - | 전체 유저 조회 |
| GET | `/users/:id` | - | 유저 단건 조회 |
| PUT | `/users/:id` | - | 유저 수정 |
| DELETE | `/users/:id` | - | 유저 삭제 |
| POST | `/auth/login` | - | 로그인 → JWT 반환 |
| GET | `/users/me` | JWT | 내 정보 조회 |
| POST | `/users/verify-password` | JWT | 현재 비밀번호 확인 |
| PATCH | `/users/me` | JWT | 이메일/비밀번호 수정 |

---

## 인증 방식

- 로그인 성공 시 JWT 발급 (7일 유효), payload: `{ id, email }`
- 클라이언트는 `localStorage`에 토큰 저장
- 보호된 API는 `Authorization: Bearer <token>` 헤더로 요청
- 미들웨어에서 토큰 없으면 브라우저 요청은 `/login.html` 리다이렉트, API 요청은 401 반환

## 마이페이지

- 내 정보(이름, 이메일) 조회
- 현재 비밀번호 확인 후 이메일/비밀번호 수정 가능
- 이메일 변경 시 자동 로그아웃 처리

## Prisma + MySQL 연결

Prisma v7은 `schema.prisma`에 `url` 직접 설정이 안 되고, `PrismaMariaDb` 어댑터에 URL을 넘겨야 함. pool 객체로 넘기면 OS 계정으로 접속되는 문제가 있어서 문자열로 전달.

```js
const adapter = new PrismaMariaDb(process.env.DATABASE_URL);
const prisma = new PrismaClient({ adapter });
```

---

## 환경 변수 (`.env`)

```
PORT=3000
JWT_SECRET=your_secret_key
DATABASE_URL="mysql://root:1234@localhost:3306/crux_finder"
```

---

## 실행

```bash
npm run dev   # nodemon
```
