<template>
  <section class="nccf-masthead" aria-label="NOAA NESDIS">
    <a href="https://www.noaa.gov/" class="nccf-masthead-emblem">
      <img :src="emblem" alt="NOAA" width="64" height="64">
    </a>
    <div class="nccf-masthead-text">
      <a href="https://www.nesdis.noaa.gov/" class="nccf-masthead-name">
        National Environmental Satellite, Data, and Information Service
      </a>
      <a href="https://www.commerce.gov/" class="nccf-masthead-department">Department of Commerce</a>
    </div>
  </section>
</template>

<script>
import { defineComponent } from 'vue';
import emblem from '../media/noaa-emblem.svg';

export default defineComponent({
  name: 'NoaaMasthead',
  data() {
    return {
      emblem
    };
  }
});
</script>
