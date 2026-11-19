<template>
  <div class="nccf-footer">
    <nav class="nccf-footer-columns" aria-label="NOAA NESDIS">
      <div v-for="column in columns" :key="column.title" class="nccf-footer-column">
        <h2>{{ column.title }}</h2>
        <ul>
          <li v-for="link in column.links" :key="link.url">
            <a :href="link.url">{{ link.label }}</a>
          </li>
        </ul>
      </div>
    </nav>
    <div class="nccf-footer-bottom">
      <a href="https://www.noaa.gov/" class="nccf-footer-emblem">
        <img :src="emblem" alt="NOAA" width="48" height="48">
      </a>
      <ul class="nccf-footer-federal" aria-label="Federal website policies">
        <li v-for="link in federalLinks" :key="link.url">
          <a :href="link.url">{{ link.label }}</a>
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
import { defineComponent } from 'vue';
import emblem from '../media/noaa-emblem.svg';

// Links mirror the footer of www.nesdis.noaa.gov (simplified).
const COLUMNS = [
  {
    title: 'NESDIS',
    links: [
      { label: 'About NESDIS', url: 'https://www.nesdis.noaa.gov/about/our-mission' },
      { label: 'Our Offices', url: 'https://www.nesdis.noaa.gov/about/our-offices' },
      { label: 'Contact', url: 'https://www.nesdis.noaa.gov/about/contact-us' }
    ]
  },
  {
    title: 'Data & Imagery',
    links: [
      { label: 'Real-Time Imagery', url: 'https://www.nesdis.noaa.gov/imagery/satellite-maps' },
      { label: 'Imagery Collections', url: 'https://www.nesdis.noaa.gov/imagery/imagery-collections' }
    ]
  },
  {
    title: 'NOAA',
    links: [
      { label: 'NOAA.gov', url: 'https://www.noaa.gov/' },
      { label: 'U.S. Department of Commerce', url: 'https://www.commerce.gov/' }
    ]
  }
];

const FEDERAL_LINKS = [
  { label: 'Accessibility', url: 'https://www.noaa.gov/accessibility' },
  { label: 'Disclaimer', url: 'https://www.noaa.gov/disclaimer' },
  { label: 'EEO', url: 'https://www.noaa.gov/civil-rights' },
  { label: 'FOIA', url: 'https://www.noaa.gov/information-technology/foia' },
  { label: 'Information Quality', url: 'https://www.noaa.gov/organization/information-technology/policy-oversight/information-quality' },
  { label: 'Privacy Policy', url: 'https://www.noaa.gov/protecting-your-privacy' },
  { label: 'USA.gov', url: 'https://www.usa.gov/' }
];

export default defineComponent({
  name: 'NoaaFooter',
  data() {
    return {
      emblem,
      columns: COLUMNS,
      federalLinks: FEDERAL_LINKS
    };
  }
});
</script>
