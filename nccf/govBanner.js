// Reads the fork-only `nccfGovBanner` option (see nccf/README.md).
//
// The option is not in config.schema.json, so the Docker entrypoint writes it to
// runtime-config.js as a JSON string ("false", "1", …). Build-time config may
// pass a real boolean, and SB_* env vars parsed by yargs in vite.config.js turn
// "1"/"0" into numbers. Anything unrecognised, including a missing option, is off.
const ON = new Set(['true', 't', 'yes', 'y', '1']);

export function isGovBannerEnabled(value) {
  if (typeof value === 'boolean') {
    return value;
  }
  if (typeof value === 'number') {
    return value === 1;
  }
  if (typeof value === 'string') {
    return ON.has(value.trim().toLowerCase());
  }
  return false;
}
