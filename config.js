module.exports = {
    catalogUrl: null,
    catalogTitle: "STAC Browser",
    catalogImage: null,
    allowExternalAccess: true, // Must be true if catalogUrl is not given
    allowedDomains: [],
    detectLocaleFromBrowser: true,
    storeLocale: true,
    locale: "en",
    fallbackLocale: "en",
    supportedLocales: [
        "de",
        "ar",
//      "de-CH",
        "es",
        "en",
//      "en-GB",
//      "en-US",
        "fr",
//      "fr-CA",
//      "fr-CH",
        "it",
//      "it-CH",
        "ro",
        "ja",
        "pt",
//      "pt-BR",
        "id",
        "pl"
    ],
    apiCatalogPriority: null,
    useTileLayerAsFallback: false,
    displayGeoTiffByDefault: false,
    displayPreview: true,
    displayOverview: true,
    buildTileUrlTemplate: null,
    getMapSourceOptions: null,
    pathPrefix: "/stac/browser/",
    historyMode: "history",
    cardViewMode: "cards",
    cardViewSort: "asc",
    showKeywordsInItemCards: false,
    showKeywordsInCatalogCards: false,
    showThumbnailsAsAssets: false,
    searchResultsPerPage: null,
    itemsPerPage: null,
    collectionsPerPage: null,
    maxEntriesPerPage: 1000,
    defaultThumbnailSize: null,
    crossOriginMedia: null,
    requestHeaders: {},
    requestQueryParameters: {},
    socialSharing: ['email', 'bsky', 'mastodon', 'x'],
    preprocessSTAC: (stac, state) => {
        const API_GATEWAY_PATTERN = /https?:\/\/[^/]+\.execute-api\.[^/]+/i;
        const PROXY_BASE = 'https://data-dev.nesdis.noaa.gov/stac/api';
        
        if (stac && Array.isArray(stac.links)) {
            stac.links = stac.links.map(link => {
                if (link.href && API_GATEWAY_PATTERN.test(link.href)) {
                    try {
                        const url = new URL(link.href);
                        const path = url.pathname;
                        const search = url.search;
                        const hash = url.hash;
                        
                        // Ensure path starts with /stac/api
                        const normalizedPath = path.startsWith('/stac/api') 
                            ? path 
                            : `/stac/api${path.startsWith('/') ? path : '/' + path}`;
                        
                        // Reconstruct URL with proxy domain
                        link.href = `${PROXY_BASE}${normalizedPath}${search}${hash}`;
                    } catch (e) {
                        // If URL parsing fails, skip this link
                        console.warn('Failed to rewrite URL:', link.href, e);
                    }
                }
                return link;
            });
        }
        
        return stac;
    },
    authConfig: null,
    crs: {}
};
