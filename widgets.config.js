import { defineAsyncComponent } from 'vue';
// NCCF: NOAA NESDIS chrome, see nccf/README.md
import { isGovBannerEnabled } from './nccf/govBanner.js';

export default {
  'root-start': [
    {
      id: 'NoaaGovBanner',
      component: defineAsyncComponent(() => import('./nccf/components/NoaaGovBanner.vue')),
      condition: ({ state }) => isGovBannerEnabled(state.nccfGovBanner)
    },
    {
      id: 'NoaaMasthead',
      component: defineAsyncComponent(() => import('./nccf/components/NoaaMasthead.vue'))
    }
  ],
  'footer-start': [
    {
      id: 'NoaaFooter',
      component: defineAsyncComponent(() => import('./nccf/components/NoaaFooter.vue'))
    }
  ]
};
