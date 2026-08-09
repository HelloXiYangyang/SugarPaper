<script setup lang="ts">
const entries = [
  { icon: '作业', title: '我的作业', summary: '今天 4 · 逾期 1' },
  { icon: '徽章', title: '我的徽章', summary: '3 枚已解锁', badges: true },
  { icon: '便签', title: '我的便签', summary: '3 条' },
  { icon: '收藏', title: '收藏的作业', summary: '2 条' },
  { icon: '科目', title: '科目管理', summary: '16 科' },
  { icon: '教师', title: '教师模式', summary: '' },
  { icon: '家庭', title: '家庭模式', summary: '2 成员' },
  { icon: '设置', title: '设置', summary: '' }
];
const badgeColors = ['#1677FF', '#E88A3C', '#7C6AE8'];
</script>

<template>
  <div class="me">
    <header class="topbar"><h1>我的</h1></header>

    <button class="profile">
      <span class="avatar">糖</span>
      <span class="info">
        <b>喜羊羊</b>
        <small>短ID: ab12…cd34 · 已同步</small>
      </span>
      <span class="go">›</span>
    </button>

    <section class="list">
      <button v-for="e in entries" :key="e.title" class="entry">
        <span class="eicon">{{ e.icon }}</span>
        <span class="etitle">{{ e.title }}</span>
        <span v-if="e.badges" class="badges">
          <span v-for="c in badgeColors" :key="c" class="mini" :style="{ background: c }" />
        </span>
        <span v-else class="esummary">{{ e.summary }}</span>
        <span class="go">›</span>
      </button>
    </section>
  </div>
</template>

<style scoped>
.me { display: flex; flex-direction: column; gap: 16px; padding-top: 16px; }
.topbar h1 { font-size: 22px; margin: 0; }
.profile {
  display: flex; align-items: center; gap: 12px; width: 100%;
  border: 1px solid var(--border); border-radius: var(--radius-xl); background: var(--surface);
  padding: 16px; cursor: pointer; text-align: left;
}
.avatar {
  width: 52px; height: 52px; border-radius: 50%; flex: none;
  background: linear-gradient(135deg, var(--brand-gradient-from), var(--brand-gradient-to));
  color: #fff; display: flex; align-items: center; justify-content: center; font-size: 20px;
}
.info { flex: 1; display: flex; flex-direction: column; gap: 3px; }
.info b { color: var(--text); font-size: 16px; }
.info small { color: var(--text-3); font-size: 12px; }
.go { color: var(--text-3); font-size: 20px; }
.list { border: 1px solid var(--border); border-radius: var(--radius-xl); background: var(--surface); overflow: hidden; }
.entry {
  display: flex; align-items: center; gap: 12px; width: 100%;
  padding: 14px 16px; border: none; border-bottom: 1px solid var(--divider);
  background: none; cursor: pointer; text-align: left;
}
.entry:last-child { border-bottom: none; }
.eicon {
  width: 32px; height: 32px; border-radius: 10px; flex: none;
  background: var(--surface-alt); color: var(--text-2); font-size: 12px;
  display: flex; align-items: center; justify-content: center;
}
.etitle { flex: 1; color: var(--text); font-size: 14px; font-weight: 500; }
.esummary { color: var(--text-3); font-size: 12px; }
.badges { display: flex; gap: 4px; }
.mini { width: 18px; height: 18px; border-radius: 50%; }
</style>
