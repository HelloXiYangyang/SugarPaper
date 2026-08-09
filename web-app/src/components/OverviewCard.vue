<script setup lang="ts">
defineProps<{ percent: number; streak: number; xp: number }>();
</script>

<template>
  <button class="overview-card">
    <div class="ring" :style="{ '--p': percent + '%' }">
      <span class="ring-num">{{ percent }}%</span>
    </div>
    <div class="info">
      <div class="row"><span class="key">今日进度</span><b>{{ percent }}%</b></div>
      <div class="row"><span class="key">连续完成</span><b>{{ streak }} 天</b></div>
      <div class="row"><span class="key">今日 XP</span><b>{{ xp }}</b></div>
    </div>
    <span class="go">›</span>
  </button>
</template>

<style scoped>
.overview-card {
  display: flex; align-items: center; gap: 18px; width: 100%;
  padding: 18px; border: 1px solid var(--border); border-radius: var(--radius-xl);
  background: var(--surface); box-shadow: var(--shadow-sm); cursor: pointer;
  color: var(--text); text-align: left;
}
.ring {
  width: 72px; height: 72px; border-radius: 50%; flex: none;
  background: conic-gradient(var(--brand-primary) var(--p), var(--surface-2) 0);
  display: flex; align-items: center; justify-content: center;
}
.ring::before { content: ''; position: absolute; }
.ring-num {
  width: 56px; height: 56px; border-radius: 50%; background: var(--surface);
  display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 15px;
}
.info { flex: 1; display: flex; flex-direction: column; gap: 6px; }
.row { display: flex; justify-content: space-between; font-size: 13px; }
.key { color: var(--text-2); }
.go { color: var(--text-3); font-size: 22px; }
</style>
