# NCCF customizations

Fork-owned code for the NCCF deployment of STAC Browser. Everything here is new
to the fork, so upstream merges from radiantearth/stac-browser never touch it.

## NOAA NESDIS theme

Makes the app look like a NOAA NESDIS site (<https://www.nesdis.noaa.gov/>):
US government banner, NOAA masthead, blue NESDIS nav bar and footer, NESDIS
colours and fonts. Light mode only.

| Path | Purpose |
| ---- | ------- |
| `theme/noaa.scss` | Entry point: palette, typography, Bootstrap overrides |
| `theme/_fonts.scss`, `fonts/` | Bundled Open Sans / Source Sans 3 (SIL OFL 1.1) |
| `theme/_chrome.scss` | Banner, masthead, nav bar and footer styles |
| `components/` | `NoaaGovBanner`, `NoaaMasthead`, `NoaaFooter` |
| `media/noaa-emblem.svg` | NOAA emblem, from nesdis.noaa.gov |
| `govBanner.js` | Reads the `nccfGovBanner` option |

### Upstream touch points

The theme reaches the app through two upstream extension points only:

- `src/theme/custom.scss`: one `@import` of `theme/noaa.scss`. Upstream ships
  this file empty and promises never to change it (see `docs/styling.md`).
- `widgets.config.js`: puts the banner and masthead in the `root-start` hook
  and the footer in `footer-start`. Upstream ships it as `export default {}`.

Don't edit `src/theme/variables.scss`, `page.scss` or other upstream files for
NCCF styling; add overrides to `theme/noaa.scss` instead. Bootstrap compiled
some colours into its CSS, so changing a Sass variable here has no effect.
Override the `--bs-*` / `--sb-*` custom properties or re-declare the rule.

## Options

Set in `nccf.config.js`, overridable per deployment with `SB_*` environment
variables (at build time or container start).

### nccfGovBanner

Show the "An official website of the United States government" banner.
Default `true`. Its "Here's how you know" text vouches for `.gov` + HTTPS, so
turn it off on deployments that don't run under a `.gov` domain:

```bash
docker run -e SB_nccfGovBanner=false … ghcr.io/techtraverse/nccf-stac-browser
```

Accepts `true/false`, `yes/no`, `y/n`, `t/f`, `1/0` (any case). Anything else
counts as off.

## Tests

```bash
node --test 'nccf/tests/*.test.js'
npx eslint nccf
```

The e2e suite (`npm run test:e2e`) checks that the theme doesn't break the app.
Once upstream's e2e widget config is merged, the e2e builds swap out
`widgets.config.js`, so the NOAA components are checked by hand in the browser.
