<script setup lang="ts">
const week = [4, 6, 5, 7, 3, 5, 6];
const max = Math.max(...week);
</script>

<template>
  <div class="stats">
    <header class="topbar">
      <h1>统计</h1>
      <div class="seg"><button class="on">本周</button><button>本月</button></div>
    </header>

    <section class="card summary">
      <div class="ring"><span>68%</span></div>
      <div class="rows">
        <div><span>今日 XP</span><b>45</b></div>
        <div><span>连续完成</span><b>3 天</b></div>
        <div><span>本周完成</span><b>36 项</b></div>
      </div>
    </section>

    <section class="card">
      <h2>每日完成趋势</h2>
      <div class="bars">
        <div v-for="(v, i) in week" :key="i" class="bar-col">
          <div class="bar" :style="{ height: (v / max) * 120 + 'px' }" />
          <span>{{ ['一', '二', '三', '四', '五', '六', '日'][i] }}</span>
        </div>
      </div>
    </section>

    <button class="report-btn">查看详细报告 ›</button>
  </div>
</template>

<style scoped>
.stats { display: flex; flex-direction: column; gap: 16px; padding-top: 16px; }
.topbar { display: flex; align-items: center; gap: 12px; }
h1 { flex: 1; font-size: 22px; margin: 0; }
.seg { display: flex; border: 1px solid var(--border); border-radius: var(--radius-pill); overflow: hidden; }
.seg button { border: none; background: var(--surface); padding: 6px 14px; cursor: pointer; color: var(--text-2); }
.seg button.on { background: var(--brand-primary); color: #fff; }
.card { border: 1px solid var(--border); border-radius: var(--radius-xl); background: var(--surface); padding: 18px; }
.summary { display: flex; align-items: center; gap: 20px; }
.ring {
  width: 84px; height: 84px; border-radius: 50%; flex: none;
  background: conic-gradient(var(--brand-primary) 68%, var(--surface-2) 0);
  display: flex; align-items: center; justify-content: center;
}
.ring span {
  width: 66px; height: 66px; border-radius: 50%; background: var(--surface);
  display: flex; align-items: center; justify-content: center; font-weight: 700;
}
.rows { flex: 1; display: flex; flex-direction: column; gap: 8px; font-size: 13px; }
.rows div { display: flex; justify-content: space-between; }
.rows span { color: var(--text-2); }
h2 { font-size: 14px; margin: 0 0 14px; }
.bars { display: flex; align-items: flex-end; gap: 12px; height: 150px; }
.bar-col { flex: 1; display: flex; flex-direction: column; align-items: center; gap: 6px; height: 100%; justify-content: flex-end; }
.bar { width: 100%; max-width: 28px; border-radius: 8px 8px 0 0; background: linear-gradient(180deg, var(--brand-gradient-from), var(--brand-gradient-to)); }
.bar-col span { font-size: 11px; color: var(--text-3); }
.report-btn {
  padding: 12px; border: 1px solid var(--border); border-radius: var(--radius-lg);
  background: var(--surface); cursor: pointer; color: var(--brand-primary); font-size: 14px;
}
</style>
