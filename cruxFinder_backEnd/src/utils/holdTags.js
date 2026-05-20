export const HOLD_TYPE_TAGS = Object.freeze([
  'jug',
  'crimp',
  'pinch',
  'sloper',
  'pocket',
  'volume',
]);

export const HOLD_DIRECTION_TAGS = Object.freeze([
  'up',
  'down',
  'left',
  'right',
  'both',
  'none',
]);

export const HOLD_SIZE_TAGS = Object.freeze([
  's',
  'm',
  'l',
]);

export const WALL_TAGS = Object.freeze([
  'slab',
  'vertical',
  'overhang',
]);

export const TAG_GROUPS = Object.freeze({
  holdType: HOLD_TYPE_TAGS,
  holdDirection: HOLD_DIRECTION_TAGS,
  holdSize: HOLD_SIZE_TAGS,
  wall: WALL_TAGS,
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

  if (tags.directionTag != null && !isValidTag('holdDirection', tags.directionTag)) {
    errors.push(`Invalid hold direction tag: ${tags.directionTag}`);
  }

  if (tags.sizeTag != null && !isValidTag('holdSize', tags.sizeTag)) {
    errors.push(`Invalid hold size tag: ${tags.sizeTag}`);
  }

  return errors;
}

export function validateWallTags(wallTags = []) {
  return wallTags
    .filter((tag) => !isValidTag('wall', tag))
    .map((tag) => `Invalid wall tag: ${tag}`);
}