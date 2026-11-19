# NOAA NESDIS theme for the NCCF STAC Browser — design

Date: 2026-11-18 · Branch: `noaa-theme` (off `nccf-stac-browser`)

## Intent

The NCCF deployment of STAC Browser should look and feel like a NOAA NESDIS
website (reference: <https://www.nesdis.noaa.gov/>), so visitors recognise it as
an official NOAA service. The fork is kept as a thin layer over
radiantearth/stac-browser: the overriding constraint is that upstream merges stay
conflict-free.

## Goals

- NESDIS identity chrome:
  - USWDS-style "An official website of the United States government" banner
    (grey `#F1F1F1`) with a working "Here's how you know" disclosure, switchable
    per deployment (see "Gov banner setting").
  - White masthead: NOAA emblem, "National Environmental Satellite, Data, and
    Information Service", "DEPARTMENT OF COMMERCE".
  - The existing STAC Browser header restyled as the NESDIS blue nav bar
    (`#0A4595`, white bold text and buttons). It keeps the catalog title
    ("NCCF Product Catalog", links to root) and all existing buttons.
  - Blue NOAA footer with NOAA/NESDIS links (multi-column like nesdis.noaa.gov,
    simplified), NOAA emblem and the standard federal links row
    (Accessibility, Disclaimer, Privacy Policy, FOIA, Information Quality, USA.gov).
- NESDIS palette and type across the app: primary/link `#0A4595`, body text
  `#1B1B1B`, Open Sans for body and headings, Source Sans 3 (successor of
  Source Sans Pro) for nav bar and card titles.
- All Bootstrap components that bake the old primary (`#188191`) in at compile
  time (buttons, outline buttons, form focus, checks, pagination, list-group,
  etc.) show NESDIS blue.

## Non-goals

- Replicating nesdis.noaa.gov's navigation menu (Imagery, Our Satellites, …),
  site search box, hero images or social links. This is a data catalog, not
  nesdis.gov.
- Dark mode. NESDIS has none; it is switched off for NCCF.
- NCCF features beyond look and feel (e.g. property highlighting) — separate PR.

## Anti-goals (failure even if it "works")

- Any edit to upstream-tracked files other than the two named below
  (`src/theme/custom.scss`, `widgets.config.js`). In particular no edits to
  `src/theme/variables.scss`, `page.scss`, `StacBrowser.vue`, other `src/`
  files, `vite.config.js`, `package.json`/`package-lock.json`, `Dockerfile`, or
  upstream tests.
- Inaccessible chrome: text rendered by CSS pseudo-elements, links that don't
  work, contrast below WCAG AA.
- Breaking the upstream e2e suite (which the fork's CI runs).
- Third-party runtime requests (e.g. Google Fonts CDN).

## Constraints / facts found

- `docs/styling.md`: `src/theme/custom.scss` is shipped empty and upstream
  promises it "will never change"; its upstream history is one commit (its
  creation). It is imported last in `StacBrowser.vue`'s global `<style>`, after
  Bootstrap, bootstrap-vue-next CSS and `page.scss`.
- There is no config-file-style loader for styles (`SB_CONFIG` only covers
  `config.js` options); adding one would require editing `vite.config.js`.
- Sass variable overrides placed in `custom.scss` come too late to affect
  Bootstrap's compiled CSS. Runtime CSS custom properties (`--bs-*`, and STAC
  Browser's `--sb-*` defined on `:root` in `page.scss`) can be overridden there;
  component classes that compiled hex values in must be re-declared.
- Component `<style>` blocks import `variables.scss` but none use colour or font
  variables, so global overrides reach everything.
- `widgets.config.js` is upstream-tracked but shipped as `export default {}`;
  upstream has touched it once. Hooks used: `root-start` (top of
  `#stac-browser` container, before `<header>`) and `footer-start` (inside the
  existing `<footer>`).
- e2e tests (`tests/e2e`) run against default `config.js` (not
  `nccf.config.js`), but `widgets.config.js` and `custom.scss` apply always, so
  the NOAA chrome is present in e2e runs. Tests use `page.locator('header')`,
  so the NOAA components **must not render `<header>` elements** (strict-mode
  locator would match two).
- The header hides its upper `.site` row on scroll-down using the row's height
  (`--sb-site-height`, set in `StacBrowser.vue`); the masthead sits above
  `<header>` and simply scrolls away.

## Approaches considered

- **A. Widgets + restyle (chosen).** NOAA banner/masthead/footer as Vue
  components injected through `widgets.config.js` hooks; NESDIS palette, fonts
  and the blue-bar treatment of the existing header via CSS in a file imported
  from `custom.scss`. Touches `custom.scss` (upstream-guaranteed stable) and
  `widgets.config.js` (stable, empty upstream). Real, accessible HTML.
- **B. Restyle only.** Same CSS, chrome generated with CSS pseudo-elements,
  logo via `catalogImage`, footer via `footerLinks`. Strictly zero conflict
  risk but inaccessible banner/masthead and a weaker NESDIS look. Rejected by
  the user in favour of A after weighing the one-file difference.
- **C. Edit `StacBrowser.vue` header markup.** Most faithful, guaranteed
  recurring conflicts. Ruled out.

## Design (decided)

### File layout

All fork-owned theme files live in a new top-level `nccf/` directory:

```
nccf/
  theme/
    noaa.scss          # entry point imported by src/theme/custom.scss
    _fonts.scss        # @font-face for bundled fonts
  fonts/               # woff2, latin subset, OFL licence files
  components/
    NoaaGovBanner.vue  # "An official website…" + disclosure
    NoaaMasthead.vue   # NOAA emblem + NESDIS name + Dept. of Commerce
    NoaaFooter.vue     # blue NOAA footer
  media/
    noaa-emblem.svg
  README.md            # how the NCCF theme is wired, nccfGovBanner option
```

- `src/theme/custom.scss`: one line, `@import "../../nccf/theme/noaa.scss";`
- `widgets.config.js`: `root-start` → `[NoaaGovBanner, NoaaMasthead]`,
  `footer-start` → `[NoaaFooter]`, via `defineAsyncComponent` imports from
  `nccf/components/` (the documented custom-component pattern).
- `nccf.config.js`: add `enforcedColorMode: "light"` and `nccfGovBanner: true`.
- Widgets get explicit, unique `id`s (`NoaaGovBanner`, `NoaaMasthead`,
  `NoaaFooter`). On the current base, `WidgetHook` registers components in a
  shared map keyed by id, so default `Widget<index>` ids collide across hooks
  (fixed upstream in #1068). Explicit ids work before and after that fix.

### Gov banner setting (user decision)

The "Here's how you know" text claims `.gov` + HTTPS mean the site is official,
which is only true on `.gov` hosts. The banner is therefore switchable:

- New fork-only option `nccfGovBanner` (prefixed so it can't collide with a
  future upstream option). Default `true` in `nccf.config.js`, because NCCF
  runs under `.gov` more often than not. Non-`.gov` deployments set
  `SB_nccfGovBanner=false`.
- The option is not in `config.schema.json` (upstream file). It still reaches
  the app: config keys are merged into the Vuex root state; at build time via
  `nccf.config.js` / `SB_*` env, at container start via `runtime-config.js`,
  where the entrypoint emits unknown keys as JSON strings. So the banner
  widget's `condition` must accept `true`, `"true"`, `"1"`, `"yes"`, `"y"`, `"t"`
  (case-insensitive) as on, and anything else (incl. missing) as off.
- Only the banner is switchable. Masthead, colours, fonts and footer always
  show.
- Documented in `nccf/README.md` (fork-owned; the root `README.md` is not
  edited further, to keep it merge-safe).

### Header

The masthead is a separate block above `<header>`. The existing header stays
intact: its `.site` row becomes the blue bar (flat `#0A4595`, no gradient, no
text shadow, white text, white-outline header buttons with translucent white
hover), still showing the catalog title. The `.page` row (h1 + back/parent
buttons + source) stays on white as today. Nothing is hidden.

Scroll behaviour is upstream's, unchanged: the blue bar hides on scroll-down
and returns on scroll-up; the white `.page` row stays pinned (builder's call,
to avoid fighting upstream's JS-driven header logic).

Banner and masthead render `<section aria-label="…">` wrappers, never
`<header>` or `role="banner"` (the e2e suite locates `header`, and
`HeaderTitle` already carries `role="banner"`).

### Full-bleed bands

`#stac-browser` is a Bootstrap container. Banner, masthead, header blue bar and
footer bands extend to the viewport edges (e.g. negative-margin / box-shadow or
`100vw` technique) while their content stays aligned to the container, matching
nesdis.gov. No horizontal page scroll may result.

### Colours (light mode only)

| Token | Value |
|---|---|
| primary / link | `#0A4595` (rgb 10, 69, 149) |
| link hover | darker NESDIS blue (≈ `#072F66`) |
| body text | `#1B1B1B` |
| gov banner bg | `#F1F1F1` |
| nav bar & footer bg | `#0A4595`, white text |

Set `--bs-primary`, `--bs-primary-rgb`, `--bs-link-color(-rgb)`,
`--bs-link-hover-color(-rgb)`, `--bs-primary-text-emphasis`,
`--bs-primary-bg-subtle`, `--bs-primary-border-subtle`, `--bs-body-color`,
`--bs-focus-ring-color`, `--sb-header*`; re-declare compiled-in variants
(`.btn-primary`, `.btn-outline-primary`, form focus/checked states,
pagination, etc.). Acceptance check: the built CSS has no rule in effect that
still renders `#188191` / `24, 129, 145` in light mode (grep the bundle and
verify each remaining hit is overridden).

### Typography

`--bs-body-font-family` and headings → Open Sans; nav bar and card titles →
Source Sans 3. Fonts bundled as woff2 (from the OFL-licensed `@fontsource`
packages, copied in, not added as npm dependencies) with `font-display: swap`
and the system stack as fallback.

### Assets and licensing

- NOAA emblem SVG taken from NOAA's own site assets. The emblem is for official
  NOAA use; NCCF is a NOAA/NESDIS system.
- Fonts: SIL OFL 1.1, licence text kept beside the files.
- "Powered by STAC Browser" footer credit is kept.

## Upstream sync and test coverage (builder's calls)

- Built on the current `nccf-stac-browser` base. upstream/main is 4 commits
  ahead (#1062, #1067, #1068, #1069); syncing is a separate PR, not folded in
  here. Nothing in this design touches the files those commits change.
- After that sync, upstream's `vite.config.js` swaps `widgets.config.js` for
  `tests/e2e/widgets.config.js` in e2e builds, so the NOAA components won't
  appear in e2e runs (until then they do and must not break it). The e2e suite
  keeps guarding that the always-on NOAA CSS doesn't break the app. The
  components themselves are verified by build, lint and the manual browser
  check; no fork-owned automated chrome test is added, since one would need
  edits to upstream test or build files.

## Verification

- `npm run lint` and `npx eslint nccf widgets.config.js nccf.config.js`
  (`npm run lint` covers only `src/`), `npm run build`, full Playwright e2e
  suite green.
- Visual check in Chrome against nesdis.noaa.gov at desktop and phone widths:
  catalog root, collection, item, search pages.
- Banner toggle: dev server with `SB_nccfGovBanner=false` hides the banner;
  default shows it.
- Fork-diff check: `git diff nccf-stac-browser...noaa-theme --stat` lists only
  `nccf/**`, `src/theme/custom.scss`, `widgets.config.js`, `nccf.config.js`
  and this spec.
- `nccf/README.md` explains where the theme lives, the `nccfGovBanner`
  option, and the one-line hooks in `custom.scss` / `widgets.config.js`.

## Left to the builder

- Exact spacing, font sizes and footer link list (follow nesdis.noaa.gov).
- Which compiled Bootstrap rules need re-declaring (driven by the grep check).
- Full-bleed technique, as long as there's no horizontal scroll.
