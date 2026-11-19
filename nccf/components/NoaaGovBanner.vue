<template>
  <section class="nccf-gov-banner" aria-label="Official website of the United States government">
    <div class="nccf-gov-banner-header">
      <svg class="nccf-flag" viewBox="0 0 16 11" aria-hidden="true" focusable="false">
        <rect width="16" height="11" fill="#fff" />
        <path d="M0 0h16v1H0zm0 2h16v1H0zm0 2h16v1H0zm0 2h16v1H0zm0 2h16v1H0zm0 2h16v1H0z" fill="#b22234" />
        <rect width="7" height="6" fill="#3c3b6e" />
      </svg>
      <span>An official website of the United States government</span>
      <button
        type="button" class="nccf-gov-banner-button"
        :aria-expanded="String(expanded)" aria-controls="nccf-gov-banner-content"
        @click="expanded = !expanded"
      >
        Here's how you know
        <svg class="nccf-chevron" :class="{ open: expanded }" viewBox="0 0 16 16" aria-hidden="true" focusable="false">
          <path d="M2 5l6 6 6-6" fill="none" stroke="currentColor" stroke-width="2" />
        </svg>
      </button>
    </div>
    <div v-show="expanded" id="nccf-gov-banner-content" class="nccf-gov-banner-content">
      <div class="nccf-gov-banner-guidance">
        <b-icon-bank2 class="nccf-gov-banner-icon" aria-hidden="true" />
        <p>
          <strong>Official websites use .gov</strong><br>
          A <strong>.gov</strong> website belongs to an official government organization in the United States.
        </p>
      </div>
      <div class="nccf-gov-banner-guidance">
        <b-icon-lock-fill class="nccf-gov-banner-icon" aria-hidden="true" />
        <p>
          <strong>Secure .gov websites use HTTPS</strong><br>
          A <strong>lock</strong> (<b-icon-lock-fill aria-label="Locked padlock" />) or <strong>https://</strong> means
          you've safely connected to the .gov website. Share sensitive information only on official, secure websites.
        </p>
      </div>
    </div>
  </section>
</template>

<script>
import { defineComponent } from 'vue';

// Standard USWDS government banner. Shown only when the nccfGovBanner option is
// on (see widgets.config.js), because its text vouches for .gov + HTTPS.
export default defineComponent({
  name: 'NoaaGovBanner',
  data() {
    return {
      expanded: false
    };
  }
});
</script>
