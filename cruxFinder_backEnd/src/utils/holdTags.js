// src/utils/holdTags.js

export const HOLD_TYPE_TAGS = Object.freeze([
  'jug',
  'pinch',
  'crimp',
  'sloper',
  'pocket',
]);

export const HOLD_SIZE_TAGS = Object.freeze([
  's',
  'm',
  'l',
]);

export const WALL_ANGLE_TAGS = Object.freeze([
  'slab',
  'vertical',
]);

export const TAG_GROUPS = Object.freeze({
  holdType: HOLD_TYPE_TAGS,
  holdSize: HOLD_SIZE_TAGS,
  wallAngle: WALL_ANGLE_TAGS,
});

export function isValidTag(groupName, tag) {
  const group = TAG_GROUPS[groupName];
  if (!group) return false;
  return group.includes(tag);
}

export function validateHoldTags(tags = {}) {
  const errors = [];

  if (tags.typeTag != null && !isValidTag('holdType', tags.typeTag)) {
    errors.push(`Invalid hold type tag: ${tags.typeTag}`);
  }

  if (tags.sizeTag != null && !isValidTag('holdSize', tags.sizeTag)) {
    errors.push(`Invalid hold size tag: ${tags.sizeTag}`);
  }

  return errors;
}

export function validateWallAngle(angle) {
  if (angle != null && !isValidTag('wallAngle', angle)) {
    return [`Invalid wall angle: ${angle}`];
  }
  return [];
}