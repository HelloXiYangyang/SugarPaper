<script setup lang="ts">
defineProps<{ active: string }>();
const emit = defineEmits<{ (e: 'select', tab: string): void }>();
const tabs = [
  { id: 'home', label: '今天' },
  { id: 'calendar', label: '日历' },
  { id: 'focus', label: '专注' },
  { id: 'stats', label: '统计' },
  { id: 'me', label: '我的' }
];
</script>

<template>
  <aside class="side-nav">
    <div class="brand">
      <img src="/icon.svg" alt="糖纸" class="brand-logo" />
      <span class="brand-name">糖纸</span>
    </div>
    <button
      v-for="t in tabs"
      :key="t.id"
      class="nav-item"
      :class="{ active: active === t.id }"
      @click="emit('select', t.id)"
    >
      <span class="dot" :class="t.id" />
      <span>{{ t.label }}</span>
    </button>
  </aside>
</template>

<style scoped>
.side-nav { display: none; }
@media (min-width: 900px) {
  .side-nav {
    display: flex; flex-direction: column; gap: 4px;
    width: 200px; min-height: 100vh; padding: var(--space-lg) var(--space-md);
    border-right: 1px solid var(--divider); background: var(--surface-alt);
  }
  .brand { display: flex; align-items: center; gap: 10px; padding: 8px 12px 20px; }
  .brand-logo { width: 28px; height: 28px; border-radius: 8px; }
  .brand-name { font-weight: 700; font-size: 16px; }
  .nav-item {
    display: flex; align-items: center; gap: 10px; padding: 10px 12px;
    border: none; background: none; border-radius: var(--radius-md); cursor: pointer;
    color: var(--text-2); font-size: 14px; text-align: left;
  }
  .nav-item:hover { background: var(--surface); }
  .nav-item.active { background: var(--brand-primary-soft); color: var(--brand-primary); font-weight: 600; }
  .dot { width: 16px; height: 16px; border-radius: 6px; background: var(--surface-2); }
  .nav-item.active .dot { background: var(--brand-primary); }
}
</style>
