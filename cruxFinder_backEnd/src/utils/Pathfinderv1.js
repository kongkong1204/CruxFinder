// src/utils/pathFinder.js
//
// 클라이밍 최적 경로 탐색 (A*)
// 입력: buildTaggedProblemJson이 만든 최종 데이터셋 (wall, user, holds)
// 출력: 손/발 이동 순서 경로
//
// ────────────────────────────────────────────────────────────
// [정규화 의존성 안내]
// 현재 holds의 x, y, width, height는 0~1로 정규화된 값이다.
// 좌표 → cm 변환(toCm)에서 이 정규화를 전제로 계산한다.
// 만약 이전 단계에서 정규화를 없애고 "픽셀 좌표"를 그대로 넘기면,
// 아래 [정규화] 표시가 붙은 부분만 수정하면 된다.
// ────────────────────────────────────────────────────────────

// ── 튜닝 가능한 가중치 상수 ───────────────────────────────────

// 홀드 난이도: 타입 x 크기 15개 조합 (값은 추후 조정)
const HOLD_DIFFICULTY = {
    jug:    { l: 1, m: 1, s: 2 },
    pocket: { l: 2, m: 3, s: 5 },
    pinch:  { l: 3, m: 5, s: 7 },
    sloper: { l: 5, m: 7, s: 8 },
    crimp:  { l: 4, m: 7, s: 10 },
};

// 비용 가중치 (각 항목의 영향력 조절)
const WEIGHTS = {
    distance: 1.0,    // 이동 거리 비용 계수
    difficulty: 1.0,  // 홀드 난이도 비용 계수
    balance: 1.0,     // 무게중심 페널티 계수
    armBend: 0.5,     // 팔 굽힘 페널티 계수 (팔을 펼수록 비용↓)
    gap: 3.0,         // 손-발 간격 부족 페널티 계수 (펴질수록 비용↓)
};

// 무게중심이 지지 다각형을 벗어났을 때 페널티
const BALANCE_PENALTY = 10;

// 신체 도달 한계에 곱하는 여유 계수 (1.0 = 딱 한계까지)
const REACH_MARGIN = 1.1;

// ── 신체 비율 상수 (한국인 평균 기준, 추후 튜닝 가능) ─────────
// 키 H에 대한 비율로 정의한다.
const BODY_RATIO = {
    shoulderWidth: 0.23,   // 어깨너비 ≈ 0.23H
    shoulderOffset: 0.15,  // 코어에서 어깨까지 (위로) ≈ 0.15H
    pelvisOffset: 0.15,    // 코어에서 골반까지 (아래로) ≈ 0.15H
};

// 무릎 굽힘 반영: 다리를 최대한 접었을 때 골반~발 최소 거리 비율 (인심 대비)
// 다리는 완전히 0까지 접히지 않으므로 최소 거리를 둔다.
const LEG_MIN_RATIO = 0.35;

// 손-발 수직간격 목표 비율 (키 대비): 이 간격에 못 미치는 만큼 페널티.
// 펴고 매달린 자세일수록 간격이 크고 페널티가 작아진다. (웅크림 억제)
const HAND_FOOT_GAP_TARGET_RATIO = 0.7;

// 코어(무게중심) 위치 가중치: 손보다 발 쪽에 무게중심이 가깝다.
// 손을 위로 뻗어도 코어가 따라 올라가지 않게 발 비중을 높인다. (손:발 = 1:3)
const CORE_WEIGHT = { hand: 1, foot: 3 };

// 코어 높이: 양발 중점에서 위로 (인심 × 이 비율)만큼 올린 곳에 코어를 고정.
// 무릎을 살짝 굽힌 높이를 가정 (서 있을 때 인심보다 낮음).
const CORE_HEIGHT_RATIO = 0.65;

// ── 좌표 / 거리 ──────────────────────────────────────────────

// [정규화] 정규화 좌표(0~1) → cm 변환
// 픽셀 좌표를 그대로 쓰게 되면 이 함수를 픽셀→cm 변환으로 바꾸면 된다.
//
// wallHeightCm은 "최하단 홀드 ~ 탑홀드 구간"의 실제 거리로 본다.
// scale(cm per 픽셀)은 findPath에서 한 번 계산해 wall._scale에 담아둔다.
// 종횡비 유지를 위해 x, y 모두 동일한 scale을 적용한다.
function toCm(hold, wall) {
    const scale = wall._scale; // cm per 픽셀 (findPath에서 주입)
    return {
        // x: 종횡비 유지 위해 imageWidth 곱한 뒤 동일 scale 적용
        x: hold.x * wall.imageWidth * scale,
        // y: imageHeight 곱한 뒤 동일 scale 적용
        y: hold.y * wall.imageHeight * scale,
    };
}

// [정규화] scale 계산: 최하단 홀드 ~ 탑홀드 구간을 wallHeightCm에 매핑
// 픽셀 좌표를 그대로 쓰게 되면 imageHeight 곱하는 부분만 빼면 된다.
function computeScale(wall, holds) {
    const ys = holds.map((h) => h.y);
    const yMax = Math.max(...ys); // 최하단 (y 큼)
    const yMin = Math.min(...ys); // 최상단 (탑홀드, y 작음)
    const pixelSpan = (yMax - yMin) * wall.imageHeight;
    return wall.heightCm / pixelSpan;
}

function dist(a, b) {
    const dx = a.x - b.x;
    const dy = a.y - b.y;
    return Math.sqrt(dx * dx + dy * dy);
}

// ── 신체 모델 ────────────────────────────────────────────────
//
// 1차 버전: 몸통을 "수직으로 세워진 막대"로 가정한다.
// 골반 - 코어 - 어깨가 y축(세로)을 따라 일직선으로 정렬돼 있다고 본다.
//
//   어깨 (shoulder)  ← 코어에서 위로 shoulderOffset
//     |
//   코어 (core)      ← 양손양발 4점의 평균
//     |
//   골반 (pelvis)    ← 코어에서 아래로 pelvisOffset
//
// 팔은 어깨에서, 다리는 골반에서 뻗어나간다.
// 도달 판정: 어깨~손 거리 ≤ 팔길이, 골반~발 거리 ≤ 다리길이

// 신체 치수를 키/암리치/인심으로부터 1회 계산해 둔다.
function computeBody(user) {
    const H = user.heightCm;
    const shoulderWidth = H * BODY_RATIO.shoulderWidth;
    // 팔길이 = (암리치 - 어깨너비) / 2
    // 암리치는 양팔 벌린 전체 길이이므로 어깨너비를 빼고 둘로 나눈다.
    const armLength = (user.armReachCm - shoulderWidth) / 2;
    // 다리길이는 인심을 그대로 사용
    const legLength = user.inseamCm;
    // 무릎 굽힘 반영: 최소 다리 거리 (다리를 최대한 접었을 때)
    const legMin = user.inseamCm * LEG_MIN_RATIO;
    // 손-발 수직간격 목표값 (이보다 좁으면 페널티)
    const handFootGapTarget = H * HAND_FOOT_GAP_TARGET_RATIO;
    return {
        H,
        shoulderWidth,
        armLength,
        legLength,
        legMin,
        handFootGapTarget,
        shoulderOffset: H * BODY_RATIO.shoulderOffset,
        pelvisOffset: H * BODY_RATIO.pelvisOffset,
    };
}

// 코어(무게중심) 위치 — 양발 중점에서 위로 고정 높이.
//
// 손은 코어 계산에 넣지 않는다. 따라서 손을 위로 뻗어도 코어/어깨가
// 따라 올라가지 않아, 손을 뻗을수록 어깨~손 거리가 벌어지며
// "팔을 펴서 매달리는" 자세가 자연스럽게 평가된다.
//
// x: 양발 중점의 x (몸이 양발 사이 중앙 위에 있다고 가정)
// y: 양발 중점에서 위로 (인심 × CORE_HEIGHT_RATIO) 올린 높이 (y는 작을수록 위)
function coreOf(limbsCm, body) {
    const footMidX = (limbsCm.leftFoot.x + limbsCm.rightFoot.x) / 2;
    const footMidY = (limbsCm.leftFoot.y + limbsCm.rightFoot.y) / 2;
    return {
        x: footMidX,
        y: footMidY - body.legLength * CORE_HEIGHT_RATIO,
    };
}

// 코어로부터 어깨/골반 위치 계산 (수직 막대 가정: x는 코어와 동일, y만 이동)
// [주의] y가 작을수록 위쪽이므로 어깨는 y를 빼고 골반은 y를 더한다.
function shoulderOf(core, body) {
    return { x: core.x, y: core.y - body.shoulderOffset };
}
function pelvisOf(core, body) {
    return { x: core.x, y: core.y + body.pelvisOffset };
}

// ── 도달 가능 여부 (신체 모델 기반 가지치기) ─────────────────
//
// 기존: "현재 사지 위치 → 목표 홀드" 거리로 판정
// 변경: 이동 후 자세에서 "어깨 → 손" / "골반 → 발" 거리가
//       팔길이 / 다리길이 안에 들어오는지로 판정
//
// limbsCm: 이동이 반영된 상태의 4지점 cm 좌표

// 손이 어깨 도달 범위 안에 있는지
function handReachableBody(limbsCm, body, hand /* 'leftHand'|'rightHand' */) {
    const core = coreOf(limbsCm, body);
    const shoulder = shoulderOf(core, body);
    return dist(shoulder, limbsCm[hand]) <= body.armLength * REACH_MARGIN;
}

// 발이 골반 도달 범위 안에 있는지
function footReachableBody(limbsCm, body, foot /* 'leftFoot'|'rightFoot' */) {
    const core = coreOf(limbsCm, body);
    const pelvis = pelvisOf(core, body);
    return dist(pelvis, limbsCm[foot]) <= body.legLength * REACH_MARGIN;
}

// 자세 전체가 신체적으로 성립하는지 (네 사지 모두 도달 범위 내)
function postureValid(limbsCm, body) {
    // 사지 도달 가능 여부만 판정. (웅크림은 무효화하지 않고 비용 페널티로 유도)
    return (
        handReachableBody(limbsCm, body, 'leftHand') &&
        handReachableBody(limbsCm, body, 'rightHand') &&
        footReachableBody(limbsCm, body, 'leftFoot') &&
        footReachableBody(limbsCm, body, 'rightFoot')
    );
}

// 손-발 수직간격 (가장 낮은 손 ~ 가장 높은 발). 클수록 몸이 펴진 자세.
function handFootGap(limbsCm) {
    const lowestHandY = Math.max(limbsCm.leftHand.y, limbsCm.rightHand.y);
    const highestFootY = Math.min(limbsCm.leftFoot.y, limbsCm.rightFoot.y);
    return highestFootY - lowestHandY;
}

// ── 홀드 난이도 ──────────────────────────────────────────────

function holdDifficulty(hold) {
    const type = hold.tags?.type;
    const size = hold.tags?.size;
    const byType = HOLD_DIFFICULTY[type];
    if (!byType) return 5; // 태그 없으면 중간값
    return byType[size] ?? 5;
}

// ── 무게중심 ─────────────────────────────────────────────────

// 무게중심 = 코어 (양발 중점 위 고정점). 무게중심 페널티/지지다각형 판정에 사용.
function centerOfMass(limbsCm, body) {
    return coreOf(limbsCm, body);
}

// 점이 다각형(지지 기반) 내부에 있는지 — ray casting
function pointInPolygon(point, polygon) {
    let inside = false;
    for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
        const xi = polygon[i].x, yi = polygon[i].y;
        const xj = polygon[j].x, yj = polygon[j].y;
        const intersect =
            (yi > point.y) !== (yj > point.y) &&
            point.x < ((xj - xi) * (point.y - yi)) / (yj - yi) + xi;
        if (intersect) inside = !inside;
    }
    return inside;
}

// 지지 다각형: 양손 양발이 그리는 볼록껍질(여기선 4점 순서 정렬)
function supportPolygon(limbsCm) {
    const pts = [
        limbsCm.leftHand,
        limbsCm.rightHand,
        limbsCm.rightFoot,
        limbsCm.leftFoot,
    ];
    // 무게중심 기준 각도 정렬로 단순 볼록다각형 구성
    const cx = pts.reduce((s, p) => s + p.x, 0) / pts.length;
    const cy = pts.reduce((s, p) => s + p.y, 0) / pts.length;
    return pts.slice().sort((a, b) =>
        Math.atan2(a.y - cy, a.x - cx) - Math.atan2(b.y - cy, b.x - cx)
    );
}

// 무게중심 페널티
function balancePenalty(limbsCm, body) {
    const com = centerOfMass(limbsCm, body);
    const poly = supportPolygon(limbsCm);
    return pointInPolygon(com, poly) ? 0 : BALANCE_PENALTY;
}

// 팔 굽힘 페널티: 어깨~손 거리가 팔길이에 가까울수록(팔을 폄) 0에 가깝고,
// 짧을수록(팔을 굽힘) 페널티가 커진다.
// 실제 클라이밍에서 팔을 펴서 매달리는 자세가 힘이 덜 들기 때문.
function armBendPenalty(limbsCm, body) {
    // 코어는 양발 중점 기준 고정점. 손을 위로 뻗을수록 어깨~손 거리가 벌어진다.
    const core = coreOf(limbsCm, body);
    const shoulder = shoulderOf(core, body);
    let penalty = 0;
    for (const hand of ['leftHand', 'rightHand']) {
        const reach = dist(shoulder, limbsCm[hand]);
        // 굽힘량 = 팔길이 - 실제 어깨~손 거리 (음수면 0으로)
        const bend = Math.max(0, body.armLength - reach);
        penalty += bend;
    }
    return penalty; // 양손 굽힘량 합
}

// 손-발 간격 부족 페널티: 목표 간격에 못 미치는 만큼 비용.
// 간격이 목표 이상이면 0, 좁을수록(웅크릴수록) 페널티가 커진다.
function gapPenalty(limbsCm, body) {
    const gap = handFootGap(limbsCm);
    return Math.max(0, body.handFootGapTarget - gap);
}

// ── 상태 헬퍼 ────────────────────────────────────────────────

const LIMBS = ['leftHand', 'rightHand', 'leftFoot', 'rightFoot'];

function stateKey(state) {
    return `${state.leftHand}_${state.rightHand}_${state.leftFoot}_${state.rightFoot}`;
}

// 상태의 각 사지를 cm 좌표로 변환
function limbsToCm(state, holdMap, wall) {
    return {
        leftHand: toCm(holdMap[state.leftHand], wall),
        rightHand: toCm(holdMap[state.rightHand], wall),
        leftFoot: toCm(holdMap[state.leftFoot], wall),
        rightFoot: toCm(holdMap[state.rightFoot], wall),
    };
}

// ── 휴리스틱 ─────────────────────────────────────────────────

// 양손 중 더 높은 손에서 탑홀드까지의 y거리 (cm)
// [정규화] y는 toCm에서 cm로 변환된 값을 사용
function heuristic(state, holdMap, wall, topHoldCm) {
    const lh = toCm(holdMap[state.leftHand], wall);
    const rh = toCm(holdMap[state.rightHand], wall);
    const higherHandY = Math.min(lh.y, rh.y); // y 작을수록 위
    return Math.max(0, higherHandY - topHoldCm.y);
}

// ── 비용 함수 ────────────────────────────────────────────────

// 한 번의 이동 비용: 이동 거리 + 도착 홀드 난이도 + 무게중심 페널티 + 팔 굽힘 페널티
function moveCost(limb, fromState, toState, holdMap, wall, body) {
    const fromCm = toCm(holdMap[fromState[limb]], wall);
    const toCm_ = toCm(holdMap[toState[limb]], wall);
    const toLimbsCm = limbsToCm(toState, holdMap, wall);

    const distanceCost = dist(fromCm, toCm_);
    const difficultyCost = holdDifficulty(holdMap[toState[limb]]);
    const balanceCost = balancePenalty(toLimbsCm, body);
    const armBendCost = armBendPenalty(toLimbsCm, body);
    const gapCost = gapPenalty(toLimbsCm, body);

    return (
        WEIGHTS.distance * distanceCost +
        WEIGHTS.difficulty * difficultyCost +
        WEIGHTS.balance * balanceCost +
        WEIGHTS.armBend * armBendCost +
        WEIGHTS.gap * gapCost
    );
}

// ── 이웃 상태 생성 ───────────────────────────────────────────

// 한 번에 사지 하나만 이동. 가지치기 적용.
function neighbors(state, holds, holdMap, wall, body, topHold) {
    const result = [];
    const limbsCm = limbsToCm(state, holdMap, wall);

    for (const limb of LIMBS) {
        const isHand = limb === 'leftHand' || limb === 'rightHand';
        const fromCm = limbsCm[limb];

        for (const hold of holds) {
            // 점유 체크:
            // - 발이 움직일 때: 손 두 곳 + 다른 발이 점유한 홀드 금지 (양발 같은 홀드 불가)
            // - 손이 움직일 때: 발 두 곳 금지. 반대 손이 점유한 홀드는 원칙적으로 금지하되,
            //   그 홀드가 탑홀드이면 허용한다 (양손을 탑홀드에 모으는 목표 상태).
            const otherHand = limb === 'leftHand' ? 'rightHand' : 'leftHand';
            const otherFoot = limb === 'leftFoot' ? 'rightFoot' : 'leftFoot';

            if (isHand) {
                // 발이 점유한 홀드 금지
                if (state.leftFoot === hold.id || state.rightFoot === hold.id) continue;
                // 반대 손이 점유한 홀드는 탑홀드일 때만 허용
                if (state[otherHand] === hold.id && hold.id !== topHold.id) continue;
            } else {
                // 손이 점유한 홀드 금지 + 반대 발이 점유한 홀드 금지
                if (state.leftHand === hold.id || state.rightHand === hold.id) continue;
                if (state[otherFoot] === hold.id) continue;
            }
            // 자기 자신이 이미 그 홀드면 이동 의미 없음
            if (state[limb] === hold.id) continue;

            const targetCm = toCm(hold, wall);

            // 아래로 이동 금지 (y가 커지면 아래) — [정규화] y 방향 동일
            if (targetCm.y > fromCm.y) continue;

            const next = { ...state, [limb]: hold.id };
            const nextCm = limbsToCm(next, holdMap, wall);

            // 도달 가능 가지치기 (신체 모델 기반):
            // 이동 후 자세에서 네 사지 모두 어깨/골반 도달 범위 안에 들어와야 함
            if (!postureValid(nextCm, body)) continue;

            // 자세 유효성: 손은 발보다 위에 있어야 함
            const lowestHandY = Math.max(nextCm.leftHand.y, nextCm.rightHand.y);
            const highestFootY = Math.min(nextCm.leftFoot.y, nextCm.rightFoot.y);
            if (lowestHandY > highestFootY) continue; // 손이 발보다 아래면 무효

            result.push({ limb, state: next });
        }
    }

    return result;
}

// ── 초기 상태 생성 ───────────────────────────────────────────

// 시작홀드에 양손, 발은 시작홀드보다 아래에 있는 모든 발 조합 중
// 신체 모델상 자세가 성립(postureValid)하는 것만 채택.
// 양발은 서로 다른 홀드를 밟아야 한다.
function initialStates(holds, holdMap, wall, body, startHold) {
    const startCm = toCm(startHold, wall);

    // 발 후보: 시작홀드보다 아래(y 큼)에 있는 홀드
    const footCandidates = holds.filter((h) => {
        if (h.id === startHold.id) return false;
        const c = toCm(h, wall);
        return c.y > startCm.y; // 아래에 있어야 함
    });

    const states = [];
    for (const lf of footCandidates) {
        for (const rf of footCandidates) {
            // 양발은 서로 다른 홀드를 밟아야 함
            if (lf.id === rf.id) continue;
            const candidate = {
                leftHand: startHold.id,
                rightHand: startHold.id,
                leftFoot: lf.id,
                rightFoot: rf.id,
            };
            // 신체 모델상 성립하는 자세만 초기 상태로 채택
            const cm = limbsToCm(candidate, holdMap, wall);
            if (!postureValid(cm, body)) continue;
            states.push(candidate);
        }
    }
    return states;
}

// ── 목표 판정 ────────────────────────────────────────────────

// 양손이 모두 탑홀드에 도달해야 성공 (도달 순서는 무관)
function isGoal(state, topHold) {
    return state.leftHand === topHold.id && state.rightHand === topHold.id;
}

// ── A* 본체 ──────────────────────────────────────────────────

export function findPath(dataset) {
    const { wall, user, holds } = dataset;

    // [정규화] scale 주입: 최하단~탑홀드 구간을 wallHeightCm에 매핑
    wall._scale = computeScale(wall, holds);

    const holdMap = {};
    for (const h of holds) holdMap[h.id] = h;

    const startHold = holds.find((h) => h.isStart);
    const topHold = holds.find((h) => h.isTop);

    if (!startHold) return { ok: false, message: '시작홀드가 없습니다.' };
    if (!topHold) return { ok: false, message: '탑홀드가 없습니다.' };

    const topHoldCm = toCm(topHold, wall);

    // 신체 치수 1회 계산
    const body = computeBody(user);

    // 우선순위 큐 (단순 배열 기반, 작은 f 우선)
    const open = [];
    const gScore = new Map();
    const cameFrom = new Map();

    const inits = initialStates(holds, holdMap, wall, body, startHold);
    if (inits.length === 0) {
        return { ok: false, message: '초기 발 위치를 만들 수 없습니다.' };
    }

    for (const init of inits) {
        const key = stateKey(init);
        // 초기 자세도 페널티를 비용으로 반영 (펴진 시작 자세를 선호하도록)
        const initCm = limbsToCm(init, holdMap, wall);
        const g =
            WEIGHTS.balance * balancePenalty(initCm, body) +
            WEIGHTS.armBend * armBendPenalty(initCm, body) +
            WEIGHTS.gap * gapPenalty(initCm, body);
        const h = heuristic(init, holdMap, wall, topHoldCm);
        gScore.set(key, g);
        open.push({ state: init, f: g + h, g });
    }

    let goalState = null;

    while (open.length > 0) {
        // f 최소 노드 추출
        open.sort((a, b) => a.f - b.f);
        const current = open.shift();
        const curKey = stateKey(current.state);

        if (current.g > (gScore.get(curKey) ?? Infinity)) continue;

        if (isGoal(current.state, topHold)) {
            goalState = current.state;
            break;
        }

        for (const { limb, state: next } of neighbors(current.state, holds, holdMap, wall, body, topHold)) {
            const cost = moveCost(limb, current.state, next, holdMap, wall, body);
            const nextKey = stateKey(next);
            const tentativeG = current.g + cost;

            if (tentativeG < (gScore.get(nextKey) ?? Infinity)) {
                gScore.set(nextKey, tentativeG);
                cameFrom.set(nextKey, { prevKey: curKey, prevState: current.state, limb, hold: next[limb] });
                const h = heuristic(next, holdMap, wall, topHoldCm);
                open.push({ state: next, f: tentativeG + h, g: tentativeG });
            }
        }
    }

    if (!goalState) {
        return { ok: false, message: '경로를 찾을 수 없습니다.' };
    }

    // 경로 역추적
    const moves = [];
    let key = stateKey(goalState);
    let initState = null;
    while (cameFrom.has(key)) {
        const step = cameFrom.get(key);
        moves.push({ limb: step.limb, holdId: step.hold });
        initState = step.prevState; // 가장 마지막에 남는 게 초기 상태
        key = step.prevKey;
    }
    moves.reverse();

    // moves가 비어있으면(초기 상태가 곧 목표) goalState가 초기 상태
    if (!initState) initState = goalState;

    // holdId로 정규화 좌표/바운딩박스를 붙여주는 헬퍼
    // [정규화] holds의 x, y, width, height는 0~1 정규화값. 프론트가 화면 크기에 곱해 사용.
    const withCoords = (holdId) => {
        const h = holdMap[holdId];
        return {
            holdId,
            x: h.x,
            y: h.y,
            width: h.width,
            height: h.height,
        };
    };

    // moves에 step 번호(1부터)와 좌표 추가
    const movesWithCoords = moves.map((m, i) => ({
        step: i + 1,
        limb: m.limb,
        ...withCoords(m.holdId),
    }));

    return {
        ok: true,
        start: {
            leftHand: withCoords(initState.leftHand),
            rightHand: withCoords(initState.rightHand),
            leftFoot: withCoords(initState.leftFoot),
            rightFoot: withCoords(initState.rightFoot),
        },
        totalCost: gScore.get(stateKey(goalState)),
        moves: movesWithCoords, // [{ step, limb, holdId, x, y, width, height }, ...]
    };
}
