/**
 * "Show on map" button with a tile server (`buildTileUrlTemplate`).
 *
 * ol-stac only passes GeoTiff/COG and Zarr assets to the tile server, so only
 * those may get a "Show on map" button through the tile server, even if
 * `buildTileUrlTemplate` returns a URL for anything (as TiTiler-style setups do).
 * Other assets (JSON, PDF, NetCDF, ...) must not get a button and
 * `buildTileUrlTemplate` must not be called for them at all, as it may be
 * expensive. Returning `null` opts an asset out of the tile server.
 */
import { test, expect } from './fixtures.js';
import { waitForBrowserReady } from './helpers.js';
import StaticCatalog from '../fixtures/instances/static.js';

const ROOT_URL = 'https://stac.example/catalog.json';
const ITEM_URL = 'https://stac.example/item.json';

const ASSETS = {
  cog: {
    href: 'https://stac.example/cog.tif',
    type: 'image/tiff; application=geotiff; profile=cloud-optimized',
    title: 'Remote raster',
  },
  s3cog: {
    // Not readable by the browser, only through the tile server
    href: 's3://bucket/s3.tif',
    type: 'image/tiff; application=geotiff; profile=cloud-optimized',
    title: 'Bucket raster',
  },
  zarr: {
    // Doesn't declare what to render, so it's only displayable through the tile server
    href: 'https://stac.example/store.zarr',
    type: 'application/vnd.zarr; version=3',
    title: 'Zarr store',
  },
  optout: {
    // buildTileUrlTemplate returns null for it and the browser can't read s3://
    href: 's3://bucket/optout.tif',
    type: 'image/tiff; application=geotiff; profile=cloud-optimized',
    title: 'Opted-out raster',
  },
  metadata: {
    href: 'https://stac.example/metadata.json',
    type: 'application/json',
    title: 'Metadata JSON',
  },
  pdf: {
    href: 'https://stac.example/report.pdf',
    type: 'application/pdf',
    title: 'PDF report',
  },
  netcdf: {
    href: 'https://stac.example/data.nc',
    type: 'application/netcdf',
    title: 'NetCDF file',
  },
};

function showButton(page, title) {
  // Collapsed assets are rendered but hidden, so count instead of checking visibility
  return page.locator('.asset', { hasText: title }).locator('button', { hasText: 'Show on map' });
}

test.describe('Tile server', () => {
  test('only GeoTiff and Zarr assets can be shown on the map and resolve a tile URL', async ({ page, worker }) => {
    const catalog = new StaticCatalog({ url: ROOT_URL });
    const item = catalog.addItem({ url: ITEM_URL });
    item.data.assets = {};
    for (const [key, asset] of Object.entries(ASSETS)) {
      item.data.assets[key] = { ...asset, roles: ['data'] };
    }
    await catalog.createServer(worker);

    await page.addInitScript(() => {
      window.__tileUrlCalls = [];
      window.STAC_BROWSER_CONFIG = {
        // Don't show a GeoTiff by default, its button would be "Hide from map" instead
        displayOverview: false,
        // TiTiler-style: returns a template for anything except the opted-out asset.
        // Async on purpose, the button must appear once the Promise resolved.
        buildTileUrlTemplate: (asset) => {
          const url = asset.getAbsoluteUrl();
          window.__tileUrlCalls.push(url);
          if (url.endsWith('/optout.tif')) {
            return Promise.resolve(null);
          }
          return Promise.resolve('https://tiles.example/{z}/{x}/{y}.png?url=' + encodeURIComponent(url));
        },
      };
    });

    await page.goto(item.getBrowserPath());
    await waitForBrowserReady(page);

    await expect(showButton(page, ASSETS.cog.title)).toHaveCount(1);
    await expect(showButton(page, ASSETS.s3cog.title)).toHaveCount(1);
    await expect(showButton(page, ASSETS.zarr.title)).toHaveCount(1);

    await expect
      .poll(() => page.evaluate(() => [...new Set(window.__tileUrlCalls)].sort()))
      .toEqual([ASSETS.cog.href, ASSETS.s3cog.href, ASSETS.zarr.href, ASSETS.optout.href].sort());

    await expect(showButton(page, ASSETS.optout.title)).toHaveCount(0);
    await expect(showButton(page, ASSETS.metadata.title)).toHaveCount(0);
    await expect(showButton(page, ASSETS.pdf.title)).toHaveCount(0);
    await expect(showButton(page, ASSETS.netcdf.title)).toHaveCount(0);
  });
});
