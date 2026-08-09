<script setup lang="ts">
import { computed, ref } from 'vue';
import HomeView from './views/HomeView.vue';
import CalendarView from './views/CalendarView.vue';
import FocusView from './views/FocusView.vue';
import StatsView from './views/StatsView.vue';
import MeView from './views/MeView.vue';
import BottomNav from './components/BottomNav.vue';
import SideNav from './components/SideNav.vue';
import { store } from './store';

type Tab = 'home' | 'calendar' | 'focus' | 'stats' | 'me';
const current = ref<Tab>('home');
const dark = computed(() => store.dark);
</script>

<template>
  <div class="app-shell" :data-theme="dark ? 'dark' : 'light'">
    <SideNav :active="current" @select="current = $event as Tab" />
    <main class="app-main">
      <HomeView v-if="current === 'home'" :dark="dark" @toggle-dark="store.toggleDark()" />
      <CalendarView v-else-if="current === 'calendar'" />
      <FocusView v-else-if="current === 'focus'" />
      <StatsView v-else-if="current === 'stats'" />
      <MeView v-else />
    </main>
    <BottomNav :active="current" @select="current = $event as Tab" />
  </div>
</template>

<style scoped>
.app-shell { min-height: 100vh; display: flex; flex-direction: column; }
.app-main { flex: 1; width: 100%; max-width: 720px; margin: 0 auto; padding: 0 var(--space-lg) 96px; }

@media (min-width: 900px) {
  .app-shell { flex-direction: row; }
  .app-main { max-width: none; margin: 0; padding: 0 var(--space-2xl) var(--space-3xl); }
}
</style>
