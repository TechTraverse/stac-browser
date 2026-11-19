# NOAA NESDIS Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the NCCF STAC Browser look like a NOAA NESDIS site (gov banner, NOAA masthead, blue nav bar, NOAA footer, NESDIS palette and fonts) without editing upstream files beyond `src/theme/custom.scss` and `widgets.config.js`.

**Architecture:** All fork-owned theme code lives in a new `nccf/` folder. `src/theme/custom.scss` (empty upstream, guaranteed stable) gets one `@import` of `nccf/theme/noaa.scss`, which overrides Bootstrap/STAC Browser CSS custom properties and re-declares compiled-in Bootstrap colours. Banner, masthead and footer are Vue components injected through `widgets.config.js` hooks `root-start` and `footer-start`.

**Tech Stack:** Vue 3, Bootstrap 5.3 / bootstrap-vue-next, Sass (modern compiler), Vite, Playwright, `node --test` (built-in, no new deps).

**Spec:** `docs/superpowers/specs/2026-11-18-noaa-theme-design.md`

## Global Constraints

- Only these upstream-tracked files may change: `src/theme/custom.scss`, `widgets.config.js`. Fork-owned: `nccf.config.js`, everything under `nccf/`, `docs/superpowers/**`. No `package.json`/lockfile changes, no new npm dependencies.
- Colours: primary/link `#0A4595` (rgb `10, 69, 149`), link hover `#072F66` (rgb `7, 47, 102`), body text `#1B1B1B` (rgb `27, 27, 27`), gov banner bg `#F1F1F1`, nav bar + footer bg `#0A4595` with white text.
- Fonts: Open Sans (body, headings), Source Sans 3 (nav bar, card titles); woff2, latin subset, `font-display: swap`, system-stack fallback; OFL licence files kept beside them. No runtime third-party requests.
- `nccf.config.js` gets `enforcedColorMode: "light"` and `nccfGovBanner: true`.
- Widget ids exactly `NoaaGovBanner`, `NoaaMasthead`, `NoaaFooter`.
- Components never render `<header>` or `role="banner"`; use `<section aria-label="…">` (banner, masthead) and `<div>` (footer, already inside upstream `<footer>`).
- Masthead copy: "National Environmental Satellite, Data, and Information Service" / "DEPARTMENT OF COMMERCE". Banner copy: standard USWDS "An official website of the United States government" / "Here's how you know" with the ".gov" and "HTTPS" explanations.
- Keep the upstream "Powered by STAC Browser" credit.

## Review Focus

1. Docker runtime passes `SB_nccfGovBanner` as a JSON *string* (`"false"`, `"FALSE"`, `"0"`, `""`) — must read as off; missing key off; boolean `true` and `"true"`/`"1"`/`"yes"`/`"y"`/`"t"` on. → Task 1 tests.
2. Phone width (375px): full-bleed bands must not cause horizontal page scroll; masthead text wraps under the emblem. → Task 3 step 6.
3. App served under `pathPrefix` `/stac/browser/` (and Docker's `base: "./"`): fonts and emblem must still load (no 404s). → Task 2 step 5, Task 3 step 6.
4. Keyboard users: visible focus ring on white-on-blue header buttons and footer links; "Here's how you know" is a `<button>` with `aria-expanded` toggling the panel. → Task 3 step 6.
5. Sticky header: scrolling down hides the blue bar and keeps the white `.page` row pinned with no gap or overlap below the scrolled-away masthead; scrolling up restores it. → Task 3 step 6.

---

### Task 1: Gov-banner setting

**Files:**
- Create: `nccf/govBanner.js`
- Create: `nccf/tests/govBanner.test.js`
- Modify: `nccf.config.js`

**Interfaces:**
- Produces: `export function isGovBannerEnabled(value: unknown): boolean` in `nccf/govBanner.js`; `nccfGovBanner` key in Vuex root state (read in Task 3 as `state.nccfGovBanner`).

- [ ] **Step 1: Write the failing test** `nccf/tests/govBanner.test.js` with `node:test` + `node:assert/strict`:
  - on: `true`, `"true"`, `"TRUE"`, `"1"`, `"yes"`, `"Y"`, `"t"`, `" true "`
  - off: `false`, `"false"`, `"FALSE"`, `"0"`, `"no"`, `""`, `null`, `undefined`, `"banana"`, `1` (non-string/non-boolean → off)
- [ ] **Step 2: Run** `node --test nccf/tests/` — Expected: FAIL (module not found).
- [ ] **Step 3: Implement** `isGovBannerEnabled` (boolean passes through; string trimmed + lower-cased against `true|t|yes|y|1`; everything else `false`).
- [ ] **Step 4: Run** `node --test nccf/tests/` — Expected: all pass.
- [ ] **Step 5: Add** `enforcedColorMode: "light"` and `nccfGovBanner: true` to `nccf.config.js`, each with a one-line comment (gov banner: set `SB_nccfGovBanner=false` on non-.gov hosts).
- [ ] **Step 6: Commit** `feat(nccf): add nccfGovBanner setting and force light mode`

### Task 2: NESDIS palette and typography

**Files:**
- Create: `nccf/fonts/` (woff2 + `OFL-OpenSans.txt`, `OFL-SourceSans3.txt`)
- Create: `nccf/theme/_fonts.scss`, `nccf/theme/noaa.scss`
- Modify: `src/theme/custom.scss` (one line: `@import "../../nccf/theme/noaa.scss";`)

**Interfaces:**
- Produces: CSS custom properties `--nccf-blue`, `--nccf-blue-dark`, `--nccf-font-body`, `--nccf-font-nav` on `:root` (used by Task 3 styles).

- [ ] **Step 1: Get fonts.** `npm pack @fontsource/open-sans @fontsource/source-sans-3` into the scratchpad, extract each into its own empty dir, copy latin woff2 for Open Sans 400/400-italic/600/700 and Source Sans 3 400/700 plus licence files into `nccf/fonts/`. Do not install into the project.
- [ ] **Step 2: Write** `_fonts.scss` (`@font-face` per file, relative `url("../fonts/…")`, `font-display: swap`) and `noaa.scss`: imports `_fonts`; on `:root, [data-bs-theme=light]` sets the `--nccf-*` tokens and overrides `--bs-primary(-rgb)`, `--bs-link-color(-rgb)`, `--bs-link-hover-color(-rgb)`, `--bs-primary-text-emphasis`, `--bs-primary-bg-subtle`, `--bs-primary-border-subtle`, `--bs-body-color(-rgb)`, `--bs-body-font-family`, `--bs-focus-ring-color`; headings font; card titles in Source Sans 3; re-declare `--bs-btn-*` for `.btn-primary` and `.btn-outline-primary` with Global Constraints values.
- [ ] **Step 3: Build** `npm run build` — Expected: succeeds; `ls dist/assets | grep woff2` lists the bundled fonts.
- [ ] **Step 4: Teal sweep.** `grep -o '#188191\|24, *129, *145\|#18819[0-9a-f]*' dist/assets/*.css | sort | uniq -c`, then for each selector still carrying it (form focus, checks, pagination, list-group, nav-pills, etc.) add an override in `noaa.scss` and rebuild until every remaining hit is shadowed by a later NOAA rule. Record the selector list in the commit message.
- [ ] **Step 5: Check prefix.** `SB_CONFIG=nccf.config.js npm start`, open `http://localhost:8080/stac/browser/`; DevTools network shows fonts 200 and computed body font `"Open Sans"`.
- [ ] **Step 6: Commit** `feat(nccf): NESDIS palette and bundled fonts via custom.scss`

### Task 3: NOAA chrome (banner, masthead, blue bar, footer)

**Files:**
- Create: `nccf/media/noaa-emblem.svg`
- Create: `nccf/components/NoaaGovBanner.vue`, `NoaaMasthead.vue`, `NoaaFooter.vue`
- Create: `nccf/theme/_chrome.scss` (imported from `noaa.scss`)
- Modify: `widgets.config.js`

**Interfaces:**
- Consumes: `isGovBannerEnabled` (Task 1), `--nccf-*` tokens (Task 2).
- Produces: `widgets.config.js` default export
  `{ 'root-start': [{id:'NoaaGovBanner', component, condition: ({state}) => isGovBannerEnabled(state.nccfGovBanner)}, {id:'NoaaMasthead', component}], 'footer-start': [{id:'NoaaFooter', component}] }` with `defineAsyncComponent(() => import('./nccf/components/…'))`.

- [ ] **Step 1: Emblem.** Take the NOAA emblem SVG used in nesdis.noaa.gov's header (or noaa.gov's if that one is raster); save as `nccf/media/noaa-emblem.svg`; open it to confirm it is a clean SVG with no scripts.
- [ ] **Step 2: Components.**
  - `NoaaGovBanner`: US flag (inline SVG/emoji-free), banner text, `<button aria-expanded aria-controls>` "Here's how you know" toggling a panel with the two USWDS explanations (`.gov` and HTTPS/lock); local `data` state, no store writes.
  - `NoaaMasthead`: emblem `<img alt="NOAA">` linking to `https://www.noaa.gov/`; NESDIS name linking to `https://www.nesdis.noaa.gov/`; "DEPARTMENT OF COMMERCE" linking to `https://www.commerce.gov/`.
  - `NoaaFooter`: columns "NESDIS" (About NESDIS, Our Satellites, Data Products), "NOAA" (NOAA.gov, U.S. Department of Commerce), then emblem + federal links row: Accessibility, Disclaimer, Privacy Policy, FOIA, Information Quality, USA.gov — all to their nesdis.noaa.gov / noaa.gov / usa.gov pages, verified to resolve in Chrome.
- [ ] **Step 3: Wire** `widgets.config.js` exactly as in Interfaces.
- [ ] **Step 4: Styles** in `_chrome.scss`: full-bleed bands (banner, masthead, header `.site` row, footer) with content aligned to the container; header `.site` → flat `--nccf-blue`, `--sb-header-background`/`--sb-header-color`/hover vars set to white variants, `text-shadow: none`, nav font Source Sans 3 700; footer blue with white links; focus rings visible on blue (white/yellow outline).
- [ ] **Step 5: Lint** `npx eslint nccf widgets.config.js nccf.config.js` and `npm run lint` — Expected: no errors (and `git status` shows `npm run lint --fix` changed nothing in `src/`).
- [ ] **Step 6: Browser check** (Chrome, dev server with `SB_CONFIG=nccf.config.js` and a public catalog via `SB_catalogUrl`): root, collection, item, search pages at 1440px and 375px against nesdis.noaa.gov; Review Focus 2–5; restart with `SB_nccfGovBanner=false` → banner absent, masthead present.
- [ ] **Step 7: Commit** `feat(nccf): NOAA gov banner, masthead, nav bar and footer`

### Task 4: Docs and full verification

**Files:**
- Create: `nccf/README.md`

- [ ] **Step 1: Write** `nccf/README.md`: what lives in `nccf/`, the two upstream touch points (`custom.scss` import line, `widgets.config.js` entries) and why, the `nccfGovBanner` option with Docker example `SB_nccfGovBanner=false`, how to run `node --test nccf/tests/`.
- [ ] **Step 2: Run** `node --test nccf/tests/`, `npm run build`, `npm run test:e2e` — Expected: all green (same pass count as on `nccf-stac-browser`; if a failure appears, compare against a run on `nccf-stac-browser` before blaming the theme).
- [ ] **Step 3: Fork-diff check** `git diff nccf-stac-browser...HEAD --stat` — Expected: only `nccf/**`, `src/theme/custom.scss`, `widgets.config.js`, `nccf.config.js`, `docs/superpowers/**`.
- [ ] **Step 4: Commit** `docs(nccf): document the NOAA theme`
