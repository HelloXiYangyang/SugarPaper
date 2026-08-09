<script setup lang="ts">
import { computed, ref } from 'vue';
import { store } from '../store';

const today = new Date();
const year = today.getFullYear();
const month = today.getMonth();
const selected = ref(today.getDate());

const days = computed(() => {
  const first = new Date(year, month, 1);
  const offset = (first.getDay() + 6) % 7; // 周一开头
  const count = new Date(year, month + 1, 0).getDate();
  const cells: (number | null)[] = [];
  for (let i = 0; i < offset; i++) cells.push(null);
  for (let d = 1; d <= count; d++) cells.push(d);
  while (cells.length % 7 !== 0) cells.push(null);
  return cells;
});

const weekday = ['一', '二', '三', '四', '五', '六', '日'];
const dayTasks = computed(() => store.tasks.filter((t) => !t.overdue && t.due.includes('今天') && selected.value === today.getDate()));
</script>

<template>
  <div class="calendar">
    <header class="topbar">
      <h1>{{ year }} 年 {{ month + 1 }} 月</h1>
      <div class="seg"><button class="on">月</button><button>周</button></div>
    </header>

    <div class="weekdays">
      <span v-for="w in weekday" :key="w">{{ w }}</span>
    </div>
    <div class="grid">
      <button
        v-for="(d, i) in days"
        :key="i"
        class="cell"
        :class="{ selected: d === selected, today: d === today.getDate() }"
        :disabled="d === null"
        @click="d !== null && (selected = d)"
      >
        <span v-if="d" class="num">{{ d }}</span>
        <span v-if="d && [5, 8, 15, 22].includes(d)" class="dot" />
      </button>
    </div>

    <section class="day-list">
      <h2>{{ month + 1 }} 月 {{ selected }} 日 · 今天</h2>
      <div v-if="dayTasks.length" class="items">
        <div v-for="t in dayTasks" :key="t.id" class="item">
          <span class="bar" :style="{ background: t.color }" />
          <span class="txt">{{ t.subject }} · {{ t.title }}</span>
        </div>
      </div>
      <p v-else class="empty">这一天没有作业</p>
    </section>
  </div>
</template>

<style scoped>
.calendar { display: flex; flex-direction: column; gap: 16px; padding-top: 16px; }
.topbar { display: flex; align-items: center; gap: 12px; }
h1 { flex: 1; font-size: 20px; margin: 0; }
.seg { display: flex; border: 1px solid var(--border); border-radius: var(--radius-pill); overflow: hidden; }
.seg button { border: none; background: var(--surface); padding: 6px 14px; cursor: pointer; color: var(--text-2); }
.seg button.on { background: var(--brand-primary); color: #fff; }
.weekdays { display: grid; grid-template-columns: repeat(7, 1fr); text-align: center; color: var(--text-3); font-size: 12px; }
.grid { display: grid; grid-template-columns: repeat(7, 1fr); gap: 4px; }
.cell {
  aspect-ratio: 1; border: none; border-radius: 12px; background: var(--surface-alt);
  position: relative; cursor: pointer; display: flex; align-items: center; justify-content: center;
}
.cell.selected { background: var(--brand-primary); }
.cell.selected .num { color: #fff; }
.cell.today .num { color: var(--brand-primary); font-weight: 700; }
.cell.selected.today .num { color: #fff; }
.num { font-size: 13px; color: var(--text); }
.dot { position: absolute; bottom: 6px; width: 5px; height: 5px; border-radius: 50%; background: var(--brand-primary); }
.day-list { border: 1px solid var(--border); border-radius: var(--radius-lg); padding: 14px; background: var(--surface); }
h2 { font-size: 14px; margin: 0 0 10px; }
.items { display: flex; flex-direction: column; gap: 8px; }
.item { display: flex; align-items: center; gap: 10px; font-size: 14px; }
.bar { width: 4px; height: 20px; border-radius: 2px; }
.txt { color: var(--text); }
.empty { color: var(--text-3); font-size: 13px; }
</style>
