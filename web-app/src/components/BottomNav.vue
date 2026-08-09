<script setup lang="ts">
defineProps<{ active: string }>();
const emit = defineEmits<{ (e: 'select', tab: string): void }>();
const tabs = [
  { id: 'home', label: '首页' },
  { id: 'calendar', label: '日历' },
  { id: 'focus', label: '专注' },
  { id: 'stats', label: '统计' },
  { id: 'me', label: '我的' }
];
</script>

<template>
  <nav class="bottom-nav">
    <button
      v-for="t in tabs"
      :key="t.id"
      class="nav-item"
      :class="{ active: active === t.id }"
      @click="emit('select', t.id)"
    >
      <span class="dot" :class="t.id" />
      <span class="label">{{ t.label }}</span>
    </button>
  </nav>
</template>

<style scoped>
.bottom-nav {
  position: fixed; left: 0; right: 0; bottom: 0;
  display: flex; background: var(--surface);
  border-top: 1px solid var(--divider);
  padding-bottom: env(safe-area-inset-bottom);
  z-index: 10;
}
.nav-item {
  flex: 1; display: flex; flex-direction: column; align-items: center; gap: 4px;
  padding: 10px 0 8px; border: none; background: none; cursor: pointer;
  color: var(--text-3);
}
.nav-item.active { color: var(--brand-primary); }
.dot { width: 22px; height: 22px; border-radius: 8px; background: var(--surface-2); }
.dot.home { background: var(--brand-primary-soft); }
.dot.calendar { background: var(--surface-2); }
.dot.focus { background: var(--surface-2); }
.dot.stats { background: var(--surface-2); }
.dot.me { background: var(--surface-2); }
.nav-item.active .dot { background: var(--brand-primary); }
.label { font-size: 12px; }

@media (min-width: 900px) { .bottom-nav { display: none; } }
</style>
