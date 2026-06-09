// src/utils/pathFinder.js
//
// 클라이밍 최적 경로 탐색 (A*)
// 입력: buildTaggedProblemJson이 만든 최종 데이터셋 (wall, user, holds)
// 출력: 손/발 이동 순서 경로
//
// ────────────────────────────────────────────────────────────
// [모델 개요]
// 상태 = 양손/양발 4지점이 각각 어느 홀드에 있는지.
// 한 번에 한 사지만 이동. 어깨/골반 같은 신체 관절 모델은 쓰지 않고,
// "현재 사지 위치 → 다음 홀드까지 거리"가 암리치/인심 이내인지로 도달 판정.
// 손-발 높이차가 작으면(웅크림) 페널티, 무게중심이 지지면 벗어나면 페널티.
//
// [정규화 의존성 안내]
// holds의 x, y, width, height는 0~1 정규화값.
// 좌표→cm 변환(toCm)과 스케일(computeScale)에서 이를 전제로 한다.
// 픽셀 좌표를 그대로 넘기게 되면 [정규화] 표시 부분만 손보면 된다.
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
    gap: 3.0,         // 손-발 높이차 부족 페널티 계수 (펴질수록 비용↓)
};

// 무게중심이 지지 다각형을 벗어났을 때 페널티
const BALANCE_PENALTY = 10;

// 신체 도달 한계에 곱하는 여유 계수 (순간적으로 뻗는 동작 허용)
const REACH_MARGIN = 1.1;

// 손-발 높이차 목표 비율 (키 대비): 이 높이차에 못 미치는 만큼 페널티.
// 손과 발이 멀리 떨어진(펴고 매달린) 자세일수록 높이차가 크고 페널티가 작다.
const HAND_FOOT_GAP_TARGET_RATIO = 0.5;

// 손-발 높이차 상한 비율 (키 대비): 이보다 크면 사람이 못 늘어나는 자세.
// 초과한 만큼 페널티 → 손이 너무 올라가면 발을 끌어올리게 유도.
const HAND_FOOT_GAP_MAX_RATIO = 1.0;

// ── 좌표 / 거리 ──────────────────────────────────────────────

// [정규화] 정규화 좌표(0~1) → cm 변환. scale은 findPath에서 wall._scale에 주입.
function toCm(hold, wall) {
    const scale = wall._scale;
    return {
        x: hold.x * wall.imageWidth * scale,
        y: hold.y * wall.imageHeight * scale,
    };
}

// [정규화] scale 계산: 최하단 홀드 ~ 최상단 홀드 구간을 wallHeightCm에 매핑.
// 픽셀 좌표를 그대로 쓰게 되면 imageHeight 곱하는 부분만 빼면 된다.
function computeScale(wall, holds) {
    const ys = holds.map((h) => h.y);
    const yMax = Math.max(...ys); // 최하단 (y 큼)
    const yMin = Math.min(...ys); // 최상단 (y 작음)
    const pixelSpan = (yMax - yMin) * wall.imageHeight;
    return wall.heightCm / pixelSpan;
}

function dist(a, b) {
    const dx = a.x - b.x;
    const dy = a.y - b.y;
    return Math.sqrt(dx * dx + dy * dy);
}

// ── 신체 치수 ────────────────────────────────────────────────

// 키/암리치/인심으로부터 도달 한계와 높이차 목표를 1회 계산.
function computeBody(user) {
    return {
        H: user.heightCm,
        armReach: user.armReachCm,     // 손 도달 한계
        inseam: user.inseamCm,         // 발 도달 한계
        gapTarget: user.heightCm * HAND_FOOT_GAP_TARGET_RATIO, // 손-발 높이차 목표(하한)
        gapMax: user.heightCm * HAND_FOOT_GAP_MAX_RATIO,       // 손-발 높이차 상한
    };
}

// ── 도달 가능 여부 (4점 거리 기반 가지치기) ──────────────────

// 손 이동: 현재 손 위치에서 다음 홀드까지 암리치 이내인가
function handReachable(fromCm, toCm_, body) {
    return dist(fromCm, toCm_) <= body.armReach * REACH_MARGIN;
}

// 발 이동: 현재 발 위치에서 다음 홀드까지 인심 이내인가
function footReachable(fromCm, toCm_, body) {
    return dist(fromCm, toCm_) <= body.inseam * REACH_MARGIN;
}

// ── 손-발 높이차 ─────────────────────────────────────────────

// 가장 낮은 손과 가장 높은 발의 수직 거리 (클수록 몸이 펴진 자세)
// [정규화] y는 cm 변환값. y가 클수록 아래.
function handFootGap(limbsCm) {
    const lowestHandY = Math.max(limbsCm.leftHand.y, limbsCm.rightHand.y);
    const highestFootY = Math.min(limbsCm.leftFoot.y, limbsCm.rightFoot.y);
    return highestFootY - lowestHandY; // 손이 위, 발이 아래면 양수
}

// 손-발 높이차 페널티: 목표(하한)에 못 미치거나 상한을 초과한 만큼 비용.
// 너무 좁으면(웅크림) 페널티, 너무 넓으면(과신장) 페널티 → 적정 범위 유도.
function gapPenalty(limbsCm, body) {
    const gap = handFootGap(limbsCm);
    if (gap < body.gapTarget) return body.gapTarget - gap; // 하한 미달
    if (gap > body.gapMax) return gap - body.gapMax;        // 상한 초과
    return 0;
}

// ── 홀드 난이도 ──────────────────────────────────────────────

function holdDifficulty(hold) {
    const type = hold.tags?.type;
    const size = hold.tags?.size;
    const byType = HOLD_DIFFICULTY[type];
    if (!byType) return 5; // 태그 없으면 중간값
    return byType[size] ?? 5;
}

// ── 무게중심 (4점 평균) ──────────────────────────────────────

function centerOfMass(limbsCm) {
    const pts = [limbsCm.leftHand, limbsCm.rightHand, limbsCm.leftFoot, limbsCm.rightFoot];
    return {
        x: pts.reduce((s, p) => s + p.x, 0) / pts.length,
        y: pts.reduce((s, p) => s + p.y, 0) / pts.length,
    };
}

// 점이 다각형 내부에 있는지 — ray casting
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

// 지지 다각형: 양손 양발 4점을 무게중심 기준 각도 정렬한 볼록다각형
function supportPolygon(limbsCm) {
    const pts = [limbsCm.leftHand, limbsCm.rightHand, limbsCm.rightFoot, limbsCm.leftFoot];
    const cx = pts.reduce((s, p) => s + p.x, 0) / pts.length;
    const cy = pts.reduce((s, p) => s + p.y, 0) / pts.length;
    return pts.slice().sort((a, b) =>
        Math.atan2(a.y - cy, a.x - cx) - Math.atan2(b.y - cy, b.x - cx)
    );
}

// 무게중심이 지지 다각형을 벗어나면 페널티
function balancePenalty(limbsCm) {
    const com = centerOfMass(limbsCm);
    const poly = supportPolygon(limbsCm);
    return pointInPolygon(com, poly) ? 0 : BALANCE_PENALTY;
}

// ── 상태 헬퍼 ────────────────────────────────────────────────

const LIMBS = ['leftHand', 'rightHand', 'leftFoot', 'rightFoot'];

function stateKey(state) {
    return `${state.leftHand}_${state.rightHand}_${state.leftFoot}_${state.rightFoot}`;
}

function limbsToCm(state, holdMap, wall) {
    return {
        leftHand: toCm(holdMap[state.leftHand], wall),
        rightHand: toCm(holdMap[state.rightHand], wall),
        leftFoot: toCm(holdMap[state.leftFoot], wall),
        rightFoot: toCm(holdMap[state.rightFoot], wall),
    };
}

// ── 휴리스틱 ─────────────────────────────────────────────────

// 더 높은 손에서 탑홀드까지의 y거리 (cm)
function heuristic(state, holdMap, wall, topHoldCm) {
    const lh = toCm(holdMap[state.leftHand], wall);
    const rh = toCm(holdMap[state.rightHand], wall);
    const higherHandY = Math.min(lh.y, rh.y); // y 작을수록 위
    return Math.max(0, higherHandY - topHoldCm.y);
}

// ── 비용 함수 ────────────────────────────────────────────────

// 한 번의 이동 비용: 이동거리 + 홀드난이도 + 무게중심 페널티 + 높이차 페널티
function moveCost(limb, fromState, toState, holdMap, wall, body) {
    const fromCm = toCm(holdMap[fromState[limb]], wall);
    const toCm_ = toCm(holdMap[toState[limb]], wall);
    const toLimbsCm = limbsToCm(toState, holdMap, wall);

    const distanceCost = dist(fromCm, toCm_);
    const difficultyCost = holdDifficulty(holdMap[toState[limb]]);
    const balanceCost = balancePenalty(toLimbsCm);
    const gapCost = gapPenalty(toLimbsCm, body);

    return (
        WEIGHTS.distance * distanceCost +
        WEIGHTS.difficulty * difficultyCost +
        WEIGHTS.balance * balanceCost +
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
            const otherHand = limb === 'leftHand' ? 'rightHand' : 'leftHand';
            const otherFoot = limb === 'leftFoot' ? 'rightFoot' : 'leftFoot';

            // 점유 체크
            if (isHand) {
                // 발이 점유한 홀드 금지
                if (state.leftFoot === hold.id || state.rightFoot === hold.id) continue;
                // 반대 손이 점유한 홀드는 탑홀드일 때만 허용(양손 모으기)
                if (state[otherHand] === hold.id && hold.id !== topHold.id) continue;
            } else {
                // 손이 점유한 홀드 금지 + 반대 발이 점유한 홀드 금지(양발 같은 홀드 불가)
                if (state.leftHand === hold.id || state.rightHand === hold.id) continue;
                if (state[otherFoot] === hold.id) continue;
            }
            // 자기 자신이 이미 그 홀드면 이동 의미 없음
            if (state[limb] === hold.id) continue;

            const targetCm = toCm(hold, wall);

            // 아래로 이동 금지 (y가 커지면 아래)
            if (targetCm.y > fromCm.y) continue;

            // 도달 가능 가지치기 (현재 사지 → 다음 홀드 거리)
            if (isHand && !handReachable(fromCm, targetCm, body)) continue;
            if (!isHand && !footReachable(fromCm, targetCm, body)) continue;

            const next = { ...state, [limb]: hold.id };
            const nextCm = limbsToCm(next, holdMap, wall);

            // 자세 유효성: 손은 발보다 위에 있어야 함
            const lowestHandY = Math.max(nextCm.leftHand.y, nextCm.rightHand.y);
            const highestFootY = Math.min(nextCm.leftFoot.y, nextCm.rightFoot.y);
            if (lowestHandY > highestFootY) continue;

            result.push({ limb, state: next });
        }
    }

    return result;
}

// ── 초기 상태 생성 ───────────────────────────────────────────

// 시작 자세: 양손은 시작홀드, 양발은 "가장 아래 두 홀드"로 고정.
// 도달 가능 여부는 따지지 않고 고정한다.
function initialStates(holds, holdMap, wall, body, startHold) {
    const sorted = holds
        .filter((h) => h.id !== startHold.id)
        .map((h) => ({ h, y: toCm(h, wall).y }))
        .sort((a, b) => b.y - a.y); // y 큰(아래) 순

    if (sorted.length < 2) return [];

    return [{
        leftHand: startHold.id,
        rightHand: startHold.id,
        leftFoot: sorted[0].h.id,       // 가장 아래
        rightFoot: sorted[1].h.id,      // 두 번째 아래
    }];
}

// ── 목표 판정 ────────────────────────────────────────────────

// 양손이 모두 탑홀드에 도달해야 성공
function isGoal(state, topHold) {
    return state.leftHand === topHold.id && state.rightHand === topHold.id;
}

// ── A* 본체 ──────────────────────────────────────────────────

export function findPath(dataset) {
    const { wall, user, holds } = dataset;

    // [정규화] scale 주입
    wall._scale = computeScale(wall, holds);

    const holdMap = {};
    for (const h of holds) holdMap[h.id] = h;

    const startHold = holds.find((h) => h.isStart);
    const topHold = holds.find((h) => h.isTop);

    if (!startHold) return { ok: false, message: '시작홀드가 없습니다.' };
    if (!topHold) return { ok: false, message: '탑홀드가 없습니다.' };

    const topHoldCm = toCm(topHold, wall);
    const body = computeBody(user);

    const open = [];
    const gScore = new Map();
    const cameFrom = new Map();

    const inits = initialStates(holds, holdMap, wall, body, startHold);
    if (inits.length === 0) {
        return { ok: false, message: '초기 상태를 만들 수 없습니다.' };
    }

    for (const init of inits) {
        const key = stateKey(init);
        // 초기 자세도 페널티를 비용으로 반영
        const initCm = limbsToCm(init, holdMap, wall);
        const g =
            WEIGHTS.balance * balancePenalty(initCm) +
            WEIGHTS.gap * gapPenalty(initCm, body);
        const h = heuristic(init, holdMap, wall, topHoldCm);
        gScore.set(key, g);
        open.push({ state: init, f: g + h, g });
    }

    let goalState = null;

    while (open.length > 0) {
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
        initState = step.prevState;
        key = step.prevKey;
    }
    moves.reverse();
    if (!initState) initState = goalState;

    // holdId로 정규화 좌표/바운딩박스를 붙여주는 헬퍼
    // [정규화] holds의 x, y, width, height는 0~1 정규화값.
    const withCoords = (holdId) => {
        const h = holdMap[holdId];
        return { holdId, x: h.x, y: h.y, width: h.width, height: h.height };
    };

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
        moves: movesWithCoords,
    };
}