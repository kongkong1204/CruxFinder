import { validateHoldTags, validateWallTags } from './holdTags.js';

function toNumber(value, fallback = null) {
  const numberValue = Number(value);
  return Number.isFinite(numberValue) ? numberValue : fallback;
}

function toPoint(prediction) {
  if (Array.isArray(prediction.points)) {
    return prediction.points.map((point) => ({
      x: toNumber(point.x, 0),
      y: toNumber(point.y, 0),
    }));
  }

  return null;
}

function normalizePrediction(prediction, index) {
  return {
    id: prediction.id ?? `hold-${index + 1}`,
    source: 'roboflow',
    sourceClass: prediction.class ?? prediction.className ?? null,
    confidence: toNumber(prediction.confidence),
    x: toNumber(prediction.x, 0),
    y: toNumber(prediction.y, 0),
    width: toNumber(prediction.width, 0),
    height: toNumber(prediction.height, 0),
    points: toPoint(prediction),
    typeTag: null,
    directionTag: null,
    sizeTag: null,
    usable: true,
  };
}

export function parseRoboflowHolds(roboflowJson = {}) {
  const predictions = Array.isArray(roboflowJson.predictions)
    ? roboflowJson.predictions
    : [];

  return predictions.map(normalizePrediction);
}

export function applyHoldTags(holds = [], holdId, tags = {}) {
  const errors = validateHoldTags(tags);

  if (errors.length > 0) {
    return { ok: false, errors, holds };
  }

  const nextHolds = holds.map((hold) => {
    if (String(hold.id) !== String(holdId)) return hold;

    return {
      ...hold,
      typeTag: tags.typeTag ?? hold.typeTag,
      directionTag: tags.directionTag ?? hold.directionTag,
      sizeTag: tags.sizeTag ?? hold.sizeTag,
      usable: tags.usable ?? hold.usable,
    };
  });

  const found = nextHolds.some((hold) => String(hold.id) === String(holdId));

  if (!found) {
    return {
      ok: false,
      errors: [`Hold not found: ${holdId}`],
      holds,
    };
  }

  return {
    ok: true,
    errors: [],
    holds: nextHolds,
  };
}

export function addManualHold(holds = [], holdData = {}) {
  const nextIndex = holds.length + 1;

  const hold = {
    id: holdData.id ?? `manual-${nextIndex}`,
    source: 'manual',
    sourceClass: holdData.sourceClass ?? 'hold',
    confidence: null,
    x: toNumber(holdData.x, 0),
    y: toNumber(holdData.y, 0),
    width: toNumber(holdData.width, 0),
    height: toNumber(holdData.height, 0),
    points: Array.isArray(holdData.points) ? holdData.points : null,
    typeTag: holdData.typeTag ?? null,
    directionTag: holdData.directionTag ?? null,
    sizeTag: holdData.sizeTag ?? null,
    usable: holdData.usable ?? true,
  };

  const errors = validateHoldTags(hold);

  if (errors.length > 0) {
    return { ok: false, errors, holds };
  }

  return {
    ok: true,
    errors: [],
    holds: [...holds, hold],
  };
}

export function removeHold(holds = [], holdId) {
  const nextHolds = holds.filter((hold) => String(hold.id) !== String(holdId));

  if (nextHolds.length === holds.length) {
    return {
      ok: false,
      errors: [`Hold not found: ${holdId}`],
      holds,
    };
  }

  return {
    ok: true,
    errors: [],
    holds: nextHolds,
  };
}

export function buildTaggedProblemJson({
  problemId = null,
  imageId = null,
  wallTags = [],
  holds = [],
  meta = {},
} = {}) {
  const wallErrors = validateWallTags(wallTags);
  const holdErrors = holds.flatMap((hold) => validateHoldTags(hold));
  const errors = [...wallErrors, ...holdErrors];

  if (errors.length > 0) {
    return {
      ok: false,
      errors,
      data: null,
    };
  }

  return {
    ok: true,
    errors: [],
    data: {
      problemId,
      imageId,
      wallTags,
      holds: holds.map((hold) => ({
        id: hold.id,
        source: hold.source,
        x: hold.x,
        y: hold.y,
        width: hold.width,
        height: hold.height,
        points: hold.points,
        typeTag: hold.typeTag,
        directionTag: hold.directionTag,
        sizeTag: hold.sizeTag,
        usable: hold.usable,
      })),
      meta,
    },
  };
}