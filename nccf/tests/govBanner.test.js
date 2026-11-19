import { test } from 'node:test';
import assert from 'node:assert/strict';
import { isGovBannerEnabled } from '../govBanner.js';

// Docker's runtime-config.js passes options missing from config.schema.json as
// JSON strings, so "false" must read as off, not as a truthy string. At build
// time vite.config.js parses SB_* with yargs, which turns "1"/"0" into numbers.
test('treats booleans and truthy strings as on', () => {
  for (const value of [true, 'true', 'TRUE', '1', 'yes', 'Y', 't', ' true ', 1]) {
    assert.equal(isGovBannerEnabled(value), true, JSON.stringify(value));
  }
});

test('treats false, falsy strings, unknown and missing values as off', () => {
  for (const value of [false, 'false', 'FALSE', '0', 'no', '', null, undefined, 'banana', 0, 2]) {
    assert.equal(isGovBannerEnabled(value), false, JSON.stringify(value));
  }
});
