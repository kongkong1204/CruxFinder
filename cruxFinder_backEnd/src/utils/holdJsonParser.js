// src/utils/holdJsonParser.js

import { validateHoldTags, validateWallAngle } from './holdTags.js';

function toNumber(value, fallback = null) {
    const numberValue = Number(value);
    return Number.isFinite(numberValue) ? numberValue : fallback;
}

export function parseRoboflowHolds(roboflowJson = {}, imageWidth, imageHeight) {
    const predictions = Array.isArray(roboflowJson.predictions)
        ? roboflowJson.predictions
        : [];

    return predictions.map((p, i) => ({
        id: p.detection_id ?? String(i),
        x: toNumber(p.x, 0),
        y: toNumber(p.y, 0),
        width: toNumber(p.width, 0),
        height: toNumber(p.height, 0),
    }));
}

export function buildTaggedProblemJson({
                                           wall = {},
                                           user = {},
                                           holds = [],
                                       } = {}) {
    const wallErrors = validateWallAngle(wall.angle);
    const holdErrors = holds.flatMap((hold) =>
        validateHoldTags({ typeTag: hold.typeTag, sizeTag: hold.sizeTag })
    );
    const errors = [...wallErrors, ...holdErrors];

    if (errors.length > 0) {
        return { ok: false, errors, data: null };
    }

    return {
        ok: true,
        errors: [],
        data: {
            wall: {
                heightCm: toNumber(wall.heightCm),
                imageWidth: toNumber(wall.imageWidth),
                imageHeight: toNumber(wall.imageHeight),
                angle: wall.angle ?? null,
            },
            user: {
                heightCm: toNumber(user.heightCm),
                armReachCm: toNumber(user.armReachCm),
                inseamCm: toNumber(user.inseamCm),
                weightKg: toNumber(user.weightKg),
            },
            holds: holds
                .filter((hold) => hold.isSelected)
                .map((hold) => ({
                    id: hold.id,
                    x: hold.x,
                    y: hold.y,
                    width: hold.width,
                    height: hold.height,
                    isStart: hold.isStart ?? false,
                    isTop: hold.isTop ?? false,
                    tags: {
                        type: hold.typeTag ?? null,
                        size: hold.sizeTag ?? null,
                    },
                })),
        },
    };
}
