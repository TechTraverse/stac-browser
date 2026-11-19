// NCCF-specific configuration, layered on top of the upstream defaults in config.js.
//
// Loaded via SB_CONFIG=nccf.config.js (see .github/workflows/publish-nccf-docker.yml
// and the "NCCF configuration" section of the README). Keeping NCCF settings here
// rather than in config.js means config.js stays identical to upstream and merges
// from radiantearth/stac-browser don't conflict.
//
// Only list options that differ from config.js. Settings that vary per environment
// (e.g. catalogUrl, a "(staging)" title) belong in SB_* environment variables set
// by the deployment at container start, which override this file.
export default {
  catalogTitle: "NCCF Product Catalog",
  pathPrefix: "/stac/browser/",
  // The NOAA theme (see nccf/README.md) is light-only, like nesdis.noaa.gov.
  enforcedColorMode: "light",
  // Fork-only option: show the "An official website of the United States
  // government" banner. Its text vouches for .gov + HTTPS, so set
  // SB_nccfGovBanner=false on deployments that don't run under a .gov domain.
  nccfGovBanner: true
};
