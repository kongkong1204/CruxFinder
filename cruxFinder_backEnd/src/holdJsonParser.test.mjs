import assert from 'node:assert/strict';
import {
  addManualHold,
  applyHoldTags,
  buildTaggedProblemJson,
  parseRoboflowHolds,
  removeHold,
} from '../src/utils/holdJsonParser.js';

const roboflowJson = {
  predictions: [
    {
      x: 120,
      y: 240,
      width: 50,
      height: 40,
      class: 'hold',
      confidence: 0.91,
    },
  ],
};

const parsed = parseRoboflowHolds(roboflowJson);

assert.equal(parsed.length, 1);
assert.equal(parsed[0].id, 'hold-1');
assert.equal(parsed[0].x, 120);
assert.equal(parsed[0].typeTag, null);

const tagged = applyHoldTags(parsed, 'hold-1', {
  typeTag: 'crimp',
  directionTag: 'up',
  sizeTag: 's',
});

assert.equal(tagged.ok, true);
assert.equal(tagged.holds[0].typeTag, 'crimp');

const invalidTagged = applyHoldTags(tagged.holds, 'hold-1', {
  typeTag: 'unknown',
});

assert.equal(invalidTagged.ok, false);

const manual = addManualHold(tagged.holds, {
  x: 200,
  y: 300,
  width: 30,
  height: 30,
  typeTag: 'jug',
  directionTag: 'both',
  sizeTag: 'm',
});

assert.equal(manual.ok, true);
assert.equal(manual.holds.length, 2);

const removed = removeHold(manual.holds, 'manual-2');

assert.equal(removed.ok, true);
assert.equal(removed.holds.length, 1);

const finalJson = buildTaggedProblemJson({
  problemId: 'problem-1',
  imageId: 'image-1',
  wallTags: ['overhang'],
  holds: removed.holds,
});

assert.equal(finalJson.ok, true);
assert.equal(finalJson.data.holds[0].directionTag, 'up');

console.log('holdJsonParser tests passed');