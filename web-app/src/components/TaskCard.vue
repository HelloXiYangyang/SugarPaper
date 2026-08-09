<script setup lang="ts">
export interface Task {
  id: string;
  title: string;
  subject: string;
  color: string;
  due: string;
  overdue?: boolean;
  done?: boolean;
}
defineProps<{ task: Task }>();
</script>

<template>
  <div class="task-card" :class="{ done: task.done, overdue: task.overdue }">
    <button class="check" :class="{ checked: task.done }" aria-label="完成" />
    <span class="subject-bar" :style="{ background: task.color }" />
    <div class="body">
      <div class="title">{{ task.title }}</div>
      <div class="due" :class="{ danger: task.overdue }">
        {{ task.overdue ? '逾期 ' + task.due : task.due }}
      </div>
    </div>
  </div>
</template>

<style scoped>
.task-card {
  display: flex; align-items: center; gap: 12px;
  padding: 14px 16px; background: var(--surface);
  border: 1px solid var(--border); border-radius: var(--radius-lg);
  margin-bottom: 10px; transition: opacity 180ms var(--ease-in-out), transform 180ms var(--ease-in-out);
}
.task-card.done { opacity: 0.55; }
.task-card.done .title { text-decoration: line-through; color: var(--text-3); }
.check {
  width: 22px; height: 22px; border-radius: 50%; flex: none;
  border: 2px solid var(--border); background: none; cursor: pointer;
}
.check.checked { background: var(--brand-primary); border-color: var(--brand-primary); }
.subject-bar { width: 4px; height: 32px; border-radius: 2px; flex: none; }
.body { flex: 1; min-width: 0; }
.title { font-size: 15px; font-weight: 500; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.due { font-size: 12px; color: var(--text-3); margin-top: 3px; }
.due.danger { color: var(--danger); font-weight: 600; }
</style>
