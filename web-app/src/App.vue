<script setup lang="ts">
import { ref } from 'vue';
import HomeView from './views/HomeView.vue';
import BottomNav from './components/BottomNav.vue';
import SideNav from './components/SideNav.vue';

type Tab = 'home' | 'calendar' | 'focus' | 'stats' | 'me';
const active = ref<Tab>('home');
const dark = ref(false);
</script>

<template>
  <div class="app-shell" :data-theme="dark ? 'dark' : 'light'">
    <SideNav :active="active" @select="active = $event" />
    <main class="app-main">
      <HomeView v-if="active === 'home'" :dark="dark" @toggle-dark="dark = !dark" />
      <div v-else class="placeholder">{{ active }} 视图（重写中）</div>
    </main>
    <BottomNav :active="active" @select="active = $event" />
  </div>
</template>

<style scoped>
.app-shell { min-height: 100vh; display: flex; flex-direction: column; }
.app-main { flex: 1; width: 100%; max-width: 720px; margin: 0 auto; padding: 0 var(--space-lg) 96px; }
.placeholder { padding: 40px 16px; color: var(--text-2); text-align: center; }

@media (min-width: 900px) {
  .app-shell { flex-direction: row; }
  .app-main { max-width: none; margin: 0; padding: 0 var(--space-2xl) var(--space-3xl); }
}
</style>
