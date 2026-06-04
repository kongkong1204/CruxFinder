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
};

// 무게중심이 지지 다각형을 벗어났을 때 페널티
const BALANCE_PENALTY = 10;

// 신체 도달 한계에 곱하는 여유 계수 (1.0 = 딱 한계까지)
const REACH_MARGIN = 1.0;

// ── 좌표 / 거리 ──────────────────────────────────────────────

// [정규화] 정규화 좌표(0~1) → cm 변환
// 픽셀 좌표를 그대로 쓰게 되면 이 함수를 픽셀→cm 변환으로 바꾸면 된다.
function toCm(hold, wall) {
    const scale = wall.heightCm / wall.imageHeight; // cm per (정규화 후 환산된) 픽셀
    return {
        // x: 종횡비 유지 위해 imageWidth 곱한 뒤 동일 scale 적용
        x: hold.x * wall.imageWidth * scale,
        // y: y * imageHeight * scale = y * heightCm
        y: hold.y * wall.imageHeight * scale,
    };
}

function dist(a, b) {
    const dx = a.x - b.x;
    const dy = a.y - b.y;
    return Math.sqrt(dx * dx + dy * dy);
}

// ── 도달 가능 여부 (가지치기) ────────────────────────────────

// 손 이동: 현재 손 위치에서 암리치 이내인가
function handReachable(fromCm, toCm_, user) {
    return dist(fromCm, toCm_) <= user.armReachCm * REACH_MARGIN;
}

// 발 이동: 현재 발 위치에서 인심 이내인가
function footReachable(fromCm, toCm_, user) {
    return dist(fromCm, toCm_) <= user.inseamCm * REACH_MARGIN;
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

// 4지점(양손양발)의 평균을 무게중심으로 단순 추정
function centerOfMass(limbsCm) {
    const pts = [limbsCm.leftHand, limbsCm.rightHand, limbsCm.leftFoot, limbsCm.rightFoot];
    const x = pts.reduce((s, p) => s + p.x, 0) / pts.length;
    const y = pts.reduce((s, p) => s + p.y, 0) / pts.length;
    return { x, y };
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

// 한 번의 이동 비용: 이동 거리 + 도착 홀드 난이도 + 무게중심 페널티
function moveCost(limb, fromState, toState, holdMap, wall) {
    const fromCm = toCm(holdMap[fromState[limb]], wall);
    const toCm_ = toCm(holdMap[toState[limb]], wall);

    const distanceCost = dist(fromCm, toCm_);
    const difficultyCost = holdDifficulty(holdMap[toState[limb]]);
    const balanceCost = balancePenalty(limbsToCm(toState, holdMap, wall));

    return (
        WEIGHTS.distance * distanceCost +
        WEIGHTS.difficulty * difficultyCost +
        WEIGHTS.balance * balanceCost
    );
}

// ── 이웃 상태 생성 ───────────────────────────────────────────

// 한 번에 사지 하나만 이동. 가지치기 적용.
function neighbors(state, holds, holdMap, wall, user) {
    const result = [];
    const limbsCm = limbsToCm(state, holdMap, wall);

    for (const limb of LIMBS) {
        const isHand = limb === 'leftHand' || limb === 'rightHand';
        const fromCm = limbsCm[limb];

        for (const hold of holds) {
            // 이미 다른 사지가 점유한 홀드면 스킵 (한 홀드 한 사지)
            if (LIMBS.some((l) => state[l] === hold.id)) continue;

            const targetCm = toCm(hold, wall);

            // 도달 가능 가지치기
            if (isHand && !handReachable(fromCm, targetCm, user)) continue;
            if (!isHand && !footReachable(fromCm, targetCm, user)) continue;

            // 아래로 이동 금지 (y가 커지면 아래) — [정규화] y 방향 동일
            if (targetCm.y > fromCm.y) continue;

            const next = { ...state, [limb]: hold.id };

            // 자세 유효성: 손은 발보다 위에 있어야 함
            const nextCm = limbsToCm(next, holdMap, wall);
            const lowestHandY = Math.max(nextCm.leftHand.y, nextCm.rightHand.y);
            const highestFootY = Math.min(nextCm.leftFoot.y, nextCm.rightFoot.y);
            if (lowestHandY > highestFootY) continue; // 손이 발보다 아래면 무효

            result.push({ limb, state: next });
        }
    }

    return result;
}

// ── 초기 상태 생성 ───────────────────────────────────────────

// 시작홀드에 양손, 발은 시작홀드보다 아래 + 인심 이내인 모든 조합
function initialStates(holds, holdMap, wall, user, startHold) {
    const startCm = toCm(startHold, wall);

    // 발 후보: 시작홀드보다 아래이고 인심 이내
    const footCandidates = holds.filter((h) => {
        if (h.id === startHold.id) return false;
        const c = toCm(h, wall);
        if (c.y <= startCm.y) return false; // 아래(y 큼)에 있어야 함
        return footReachable(startCm, c, user);
    });

    const states = [];
    for (const lf of footCandidates) {
        for (const rf of footCandidates) {
            if (lf.id === rf.id) continue;
            states.push({
                leftHand: startHold.id,
                rightHand: startHold.id,
                leftFoot: lf.id,
                rightFoot: rf.id,
            });
        }
    }
    return states;
}

// ── 목표 판정 ────────────────────────────────────────────────

// 양손 중 하나라도 탑홀드에 도달하면 성공
function isGoal(state, topHold) {
    return state.leftHand === topHold.id || state.rightHand === topHold.id;
}

// ── A* 본체 ──────────────────────────────────────────────────

export function findPath(dataset) {
    const { wall, user, holds } = dataset;

    const holdMap = {};
    for (const h of holds) holdMap[h.id] = h;

    const startHold = holds.find((h) => h.isStart);
    const topHold = holds.find((h) => h.isTop);

    if (!startHold) return { ok: false, message: '시작홀드가 없습니다.' };
    if (!topHold) return { ok: false, message: '탑홀드가 없습니다.' };

    const topHoldCm = toCm(topHold, wall);

    // 우선순위 큐 (단순 배열 기반, 작은 f 우선)
    const open = [];
    const gScore = new Map();
    const cameFrom = new Map();

    const inits = initialStates(holds, holdMap, wall, user, startHold);
    if (inits.length === 0) {
        return { ok: false, message: '초기 발 위치를 만들 수 없습니다.' };
    }

    for (const init of inits) {
        const key = stateKey(init);
        const g = 0;
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

        for (const { limb, state: next } of neighbors(current.state, holds, holdMap, wall, user)) {
            const cost = moveCost(limb, current.state, next, holdMap, wall);
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
    while (cameFrom.has(key)) {
        const step = cameFrom.get(key);
        moves.push({ limb: step.limb, holdId: step.hold });
        key = step.prevKey;
    }
    moves.reverse();

    return {
        ok: true,
        start: {
            leftHand: startHold.id,
            rightHand: startHold.id,
            leftFoot: goalState ? undefined : undefined, // 초기 발은 moves 이전 상태로 추적 가능
        },
        totalCost: gScore.get(stateKey(goalState)),
        moves, // [{ limb, holdId }, ...] 순서대로 이동
    };
}