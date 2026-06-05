// src/utils/beamSearchBeta.js
// src/routes/analysis.js의 8번, 146~175번 줄 추가 및 변경 있음 (원본은 주석 처리함)

//메시지 테스트용으로 들어가있음
//Beam Search 기반 탐색 알고리즘
//태그 입력 후 생성되는 최종 홀드 JSON을 입력으로 받아서, 시작 홀드부터 탑 홀드까지 후보 경로 여러 개를 유지하며 가장 점수가 낮은 경로를 선택하는 방식
//현재는 DB 구조 변경 없이 /analysis/tag 응답에 beta 결과를 함께 반환하도록 구성

function toNumber(value, fallback = 0) {
  const numberValue = Number(value);
  return Number.isFinite(numberValue) ? numberValue : fallback;
}

function getHoldTypePenalty(type) {
  const penalties = {
    jug: 0,
    incut: 1,
    pinch: 2,
    crimp: 3,
    sloper: 4,
    pocket: 4,
  };

  return penalties[type] ?? 2;
}

function getHoldSizePenalty(size) {
  const penalties = {
    l: 0,
    m: 1,
    s: 3,
  };

  return penalties[size] ?? 1;
}

function getHoldPenalty(hold) {
  const type = hold.tags?.type;
  const size = hold.tags?.size;

  return getHoldTypePenalty(type) + getHoldSizePenalty(size);
}

function getTechnique(from, to, moveDistanceCm, armReachCm) {
  const verticalMove = from.y - to.y;
  const horizontalMove = Math.abs(to.x - from.x);

  if (moveDistanceCm > armReachCm * 0.85) {
    return '런지 또는 다이노 가능성';
  }

  if (verticalMove > 0.18 && horizontalMove < 0.12) {
    return '하이 스텝 가능성';
  }

  if (horizontalMove > 0.25) {
    return '몸 방향 전환 또는 플래깅 가능성';
  }

  if (to.tags?.type === 'sloper') {
    return '무게중심을 낮추고 슬로퍼 압력을 유지';
  }

  if (to.tags?.type === 'crimp') {
    return '크림프 그립 주의';
  }

  return '기본 이동';
}

function distanceCm(from, to, wall) {
  const wallHeightCm = toNumber(wall.heightCm, 300);
  const imageWidth = toNumber(wall.imageWidth, 1080);
  const imageHeight = toNumber(wall.imageHeight, 1920);

  const wallWidthCm = wallHeightCm * (imageWidth / imageHeight);

  const dx = (to.x - from.x) * wallWidthCm;
  const dy = (to.y - from.y) * wallHeightCm;

  return Math.sqrt(dx * dx + dy * dy);
}

function getStartHolds(holds) {
  const taggedStarts = holds.filter((hold) => hold.isStart);

  if (taggedStarts.length > 0) {
    return taggedStarts;
  }

  return [...holds]
    .sort((a, b) => b.y - a.y)
    .slice(0, 2);
}

function getTopHold(holds) {
  const taggedTop = holds.find((hold) => hold.isTop);

  if (taggedTop) {
    return taggedTop;
  }

  return [...holds].sort((a, b) => a.y - b.y)[0];
}

function scoreMove({ from, to, topHold, wall, user }) {
  const armReachCm = toNumber(user.armReachCm, toNumber(user.heightCm, 170));
  const moveDistanceCm = distanceCm(from, to, wall);
  const distanceToTopCm = distanceCm(to, topHold, wall);

  const reachPenalty = moveDistanceCm > armReachCm
    ? (moveDistanceCm - armReachCm) * 2
    : 0;

  const downwardPenalty = to.y > from.y
    ? 30
    : 0;

  const noProgressPenalty = Math.abs(to.y - from.y) < 0.03
    ? 5
    : 0;

  const holdPenalty = getHoldPenalty(to);

  const moveCost =
    moveDistanceCm * 0.08 +
    distanceToTopCm * 0.03 +
    reachPenalty +
    downwardPenalty +
    noProgressPenalty +
    holdPenalty;

  return {
    moveCost,
    moveDistanceCm,
    technique: getTechnique(from, to, moveDistanceCm, armReachCm),
  };
}

export function createBeamSearchBeta(problem, options = {}) {
  const beamWidth = options.beamWidth ?? 5;
  const maxSteps = options.maxSteps ?? 12;

  const holds = Array.isArray(problem?.holds)
    ? problem.holds
    : [];

  const wall = problem?.wall ?? {};
  const user = problem?.user ?? {};

  if (holds.length < 2) {
    return {
      ok: false,
      message: '베타를 생성하기에는 홀드가 부족합니다.',
      algorithm: 'beam-search',
      route: [],
    };
  }

  const startHolds = getStartHolds(holds);
  const topHold = getTopHold(holds);

  if (!topHold) {
    return {
      ok: false,
      message: '탑 홀드를 찾을 수 없습니다.',
      algorithm: 'beam-search',
      route: [],
    };
  }

  let beams = startHolds.map((startHold) => ({
    holds: [startHold],
    moves: [],
    cost: 0,
    reachedTop: startHold.id === topHold.id,
  }));

  const completed = [];

  for (let step = 0; step < maxSteps; step += 1) {
    const candidates = [];

    for (const beam of beams) {
      const currentHold = beam.holds[beam.holds.length - 1];

      if (currentHold.id === topHold.id) {
        completed.push({ ...beam, reachedTop: true });
        continue;
      }

      const visitedIds = new Set(beam.holds.map((hold) => hold.id));

      const nextHolds = holds.filter((hold) => !visitedIds.has(hold.id));

      for (const nextHold of nextHolds) {
        const scored = scoreMove({
          from: currentHold,
          to: nextHold,
          topHold,
          wall,
          user,
        });

        candidates.push({
          holds: [...beam.holds, nextHold],
          moves: [
            ...beam.moves,
            {
              step: beam.moves.length + 1,
              fromHoldId: currentHold.id,
              toHoldId: nextHold.id,
              distanceCm: Math.round(scored.moveDistanceCm),
              technique: scored.technique,
            },
          ],
          cost: beam.cost + scored.moveCost,
          reachedTop: nextHold.id === topHold.id,
        });
      }
    }

    if (candidates.length === 0) {
      break;
    }

    const sorted = candidates.sort((a, b) => a.cost - b.cost);

    completed.push(...sorted.filter((candidate) => candidate.reachedTop));

    beams = sorted.slice(0, beamWidth);

    if (completed.length > 0) {
      break;
    }
  }

  const bestPath = completed.length > 0
    ? completed.sort((a, b) => a.cost - b.cost)[0]
    : beams.sort((a, b) => a.cost - b.cost)[0];

  return {
    ok: completed.length > 0,
    algorithm: 'beam-search',
    message: completed.length > 0
      ? 'Beam Search 기반 베타를 생성했습니다.'
      : '탑 홀드까지 완전히 도달하지 못해 가장 가능성 높은 경로를 반환합니다.',
    score: Math.round(bestPath.cost * 10) / 10,
    holdIds: bestPath.holds.map((hold) => hold.id),
    route: bestPath.moves,
  };
}