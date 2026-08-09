<script setup lang="ts">
import { onUnmounted, ref } from 'vue';

const total = 25 * 60;
const left = ref(total);
const running = ref(false);
let timer: number | undefined;

const C = 2 * Math.PI * 80;
function start() {
  running.value = true;
  timer = window.setInterval(() => {
    left.value -= 1;
    if (left.value <= 0) { left.value = total; running.value = false; }
  }, 1000);
}
function stop() {
  running.value = false;
  if (timer) window.clearInterval(timer);
}
onUnmounted(stop);

const scenes = ['雨声', '篝火', '图书馆', '白噪音'];
const mm = String(Math.floor(left.value / 60)).padStart(2, '0');
const ss = String(left.value % 60).padStart(2, '0');
</script>

<template>
  <div class="focus">
    <header class="topbar">
      <h1>专注</h1>
      <button class="icon-btn">设置</button>
    </header>

    <div class="ring-wrap">
      <svg viewBox="0 0 200 200" class="ring">
        <circle cx="100" cy="100" r="80" class="track" />
        <circle
          cx="100" cy="100" r="80" class="progress"
          :stroke-dasharray="C" :stroke-dashoffset="C * (1 - left / total)"
        />
      </svg>
      <div class="time">{{ mm }}:{{ ss }}</div>
    </div>

    <button class="main-btn" @click="running ? stop() : start()">
      {{ running ? '暂停' : '开始专注' }}
    </button>

    <button class="stat-line" @click="">
      <span>今日 2 番茄 · 50 分钟</span><span>›</span>
    </button>

    <section class="scenes">
      <h2>场景</h2>
      <div class="scroll">
        <button v-for="s in scenes" :key="s" class="scene">{{ s }}</button>
        <button class="scene more">更多场景 ›</button>
      </div>
    </section>
  </div>
</template>

<style scoped>
.focus { display: flex; flex-direction: column; align-items: center; gap: 18px; padding-top: 16px; }
.topbar { display: flex; align-items: center; width: 100%; }
h1 { flex: 1; font-size: 22px; margin: 0; }
.icon-btn { border: 1px solid var(--border); background: var(--surface); border-radius: var(--radius-md); padding: 6px 12px; cursor: pointer; color: var(--text-2); }
.ring-wrap { position: relative; width: 220px; height: 220px; }
.ring { width: 100%; height: 100%; transform: rotate(-90deg); }
.track { fill: none; stroke: var(--surface-2); stroke-width: 12; }
.progress { fill: none; stroke: var(--brand-primary); stroke-width: 12; stroke-linecap: round; transition: stroke-dashoffset 1s linear; }
.time { position: absolute; inset: 0; display: flex; align-items: center; justify-content: center; font-size: 34px; font-weight: 700; font-family: var(--font-mono); }
.main-btn {
  padding: 12px 44px; border: none; border-radius: var(--radius-pill);
  background: linear-gradient(135deg, var(--brand-gradient-from), var(--brand-gradient-to));
  color: #fff; font-size: 16px; font-weight: 600; cursor: pointer;
}
.stat-line {
  width: 100%; display: flex; justify-content: space-between; align-items: center;
  border: 1px solid var(--border); border-radius: var(--radius-lg); background: var(--surface);
  padding: 12px 16px; cursor: pointer; color: var(--text-2); font-size: 13px;
}
.scenes { width: 100%; text-align: left; }
h2 { font-size: 14px; margin: 0 0 10px; }
.scroll { display: flex; gap: 10px; overflow-x: auto; padding-bottom: 6px; }
.scene {
  flex: none; padding: 14px 20px; border: 1px solid var(--border); border-radius: var(--radius-lg);
  background: var(--surface); cursor: pointer; color: var(--text); font-size: 14px;
}
.scene.more { background: var(--brand-primary-soft); color: var(--brand-primary); border-color: transparent; }
</style>
