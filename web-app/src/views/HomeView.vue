<script setup lang="ts">
import { ref } from 'vue';
import OverviewCard from '../components/OverviewCard.vue';
import TaskCard, { type Task } from '../components/TaskCard.vue';
import { store } from '../store';

defineProps<{ dark: boolean }>();
const emit = defineEmits<{ (e: 'toggle-dark'): void }>();

const tasks = store.tasks;
const quick = ref('');
const expanded = ref(true);
</script>

<template>
  <div class="home">
    <header class="topbar">
      <img src="/icon.svg" alt="糖纸" class="topbar-logo" />
      <h1>今天</h1>
      <button class="icon-btn" @click="emit('toggle-dark')" aria-label="切换深浅色">{{ dark ? '浅' : '深' }}</button>
    </header>

    <OverviewCard :percent="68" :streak="3" :xp="45" />

    <form class="quick-add" @submit.prevent="store.addTask({ id: String(Date.now()), title: quick, subject: '语文', color: '#E05A5A', due: '今天' }); quick = ''">
      <input v-model="quick" placeholder="添加作业…" />
      <button type="submit" class="add-btn">＋</button>
    </form>

    <section class="group">
      <button class="group-head" @click="expanded = !expanded">
        <span>今天（{{ tasks.filter((t) => !t.overdue && !t.done).length }}）</span>
        <span class="arrow">{{ expanded ? '▾' : '▸' }}</span>
      </button>
      <template v-if="expanded">
        <TaskCard v-for="t in tasks.filter((x) => !x.overdue)" :key="t.id" :task="t" />
      </template>
    </section>

    <section class="group">
      <div class="group-head">
        <span>已逾期（1）</span>
        <button class="move-btn">移到今天</button>
      </div>
      <TaskCard v-for="t in tasks.filter((x) => x.overdue)" :key="t.id" :task="t" />
    </section>
  </div>
</template>

<style scoped>
.home { display: flex; flex-direction: column; gap: 16px; }
.topbar { display: flex; align-items: center; gap: 10px; padding: 16px 4px 0; }
.topbar-logo { width: 28px; height: 28px; border-radius: 8px; }
h1 { flex: 1; font-size: 22px; margin: 0; }
.icon-btn { border: 1px solid var(--border); background: var(--surface); border-radius: var(--radius-md); padding: 6px 10px; cursor: pointer; color: var(--text-2); }
.quick-add { display: flex; gap: 8px; }
.quick-add input {
  flex: 1; padding: 12px 14px; border: 1px solid var(--border); border-radius: var(--radius-pill);
  background: var(--surface-alt); color: var(--text); font-size: 14px; outline: none;
}
.quick-add input:focus { border-color: var(--brand-primary); }
.add-btn {
  width: 44px; border: none; border-radius: 50%; background: linear-gradient(135deg, var(--brand-gradient-from), var(--brand-gradient-to));
  color: #fff; font-size: 20px; cursor: pointer;
}
.group { border: 1px solid var(--border); border-radius: var(--radius-lg); background: var(--surface); overflow: hidden; }
.group-head {
  display: flex; justify-content: space-between; align-items: center; width: 100%;
  padding: 12px 16px; border: none; background: var(--surface-alt); cursor: pointer;
  font-weight: 600; font-size: 14px; color: var(--text);
}
.arrow { color: var(--text-3); }
.move-btn { border: none; background: var(--brand-primary-soft); color: var(--brand-primary); border-radius: var(--radius-pill); padding: 4px 10px; font-size: 12px; cursor: pointer; }
.group > :not(.group-head) { margin: 10px 10px 0; }
.group > :last-child { margin-bottom: 10px; }
</style>
