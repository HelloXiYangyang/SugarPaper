/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 番茄钟 + 专注场景（v0.15.0）
   白/粉红/棕噪音用 Web Audio API 实时合成（零音频文件、零版权、离线可用）；
   自然音场景（森林/海浪等）预留素材位，素材接入后自动启用。 */
(function (g) {
  'use strict';

  const S = g.Sugar;
  const util = S.util;
  const store = S.store;

  const SCENES = [
    { id: 'pink-noise', name: '粉红噪音', icon: 'sparkles', color: '#C9C7F0', grad: ['#E8E0F6', '#C9C7F0'] },
    { id: 'white-noise', name: '白噪音', icon: 'cloud', color: '#B3D4F0', grad: ['#E0EEF8', '#B3D4F0'] },
    { id: 'brown-noise', name: '棕噪音', icon: 'music', color: '#F0C9A8', grad: ['#F8E4D2', '#F0C9A8'] },
    { id: 'rain', name: '雨天', icon: 'cloud', color: '#A9C8E8', grad: ['#DCEAF6', '#8FA8C8'] },
    { id: 'fireplace', name: '篝火', icon: 'flame', color: '#F5A87A', grad: ['#FBE3D0', '#F5A87A'] },
    { id: 'library', name: '图书馆', icon: 'book', color: '#D8C8A8', grad: ['#F2EBDD', '#D8C8A8'] },
    { id: 'forest', name: '森林鸟鸣', icon: 'leaf', color: '#A9E0CB', grad: ['#DFF2E8', '#A9E0CB'], disabled: true, hint: '音频素材待接入' },
    { id: 'waves', name: '海浪', icon: 'wave', color: '#8FC8E8', grad: ['#DCF0F8', '#8FC8E8'], disabled: true, hint: '音频素材待接入' },
    { id: 'custom', name: '自定义声音', icon: 'music', color: '#F5C4DC', grad: ['#FBE4EE', '#F5C4DC'], custom: true }
  ];

  /* ---------- Web Audio：合成白噪音 ---------- */
  let ctx = null;
  let master = null;
  let sceneNodes = [];
  let sceneTimers = [];
  let customAudioEl = null;
  let customRole = null; // 'primary' | 'mix'

  function ensureCtx() {
    try {
      if (!ctx) {
        const AC = g.AudioContext || g.webkitAudioContext;
        if (!AC) return null;
        ctx = new AC();
        master = ctx.createGain();
        master.gain.value = (store.state.settings.focus && store.state.settings.focus.volume) || 0.6;
        master.connect(ctx.destination);
      }
      if (ctx.state === 'suspended') ctx.resume();
    } catch (e) {
      console.warn('[focus] 音频不可用：', e);
      return null;
    }
    return ctx;
  }

  function noiseBuffer(type) {
    const c = ensureCtx();
    if (!c) return null;
    const len = c.sampleRate * 2;
    const buf = c.createBuffer(1, len, c.sampleRate);
    const data = buf.getChannelData(0);
    let last = 0;
    let b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
    for (let i = 0; i < len; i++) {
      const w = Math.random() * 2 - 1;
      if (type === 'white') {
        data[i] = w;
      } else if (type === 'pink') {
        b0 = 0.99886 * b0 + w * 0.0555179;
        b1 = 0.99332 * b1 + w * 0.0750759;
        b2 = 0.969 * b2 + w * 0.153852;
        b3 = 0.8665 * b3 + w * 0.3104856;
        b4 = 0.55 * b4 + w * 0.5329522;
        b5 = -0.7616 * b5 - w * 0.016898;
        data[i] = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + w * 0.5362) * 0.11;
        b6 = w * 0.115926;
      } else {
        last = (last + 0.02 * w) / 1.02;
        data[i] = last * 3.5;
      }
    }
    return buf;
  }

  function loopNode(type) {
    const c = ensureCtx();
    if (!c) return null;
    const src = c.createBufferSource();
    src.buffer = noiseBuffer(type);
    src.loop = true;
    return src;
  }

  /** 构建单个场景的音频节点（gain 为实际音量） */
  function buildScene(id, gain) {
    const c = ensureCtx();
    if (!c || !gain || gain <= 0) return;
    const scene = SCENES.find((s) => s.id === id) || SCENES[0];
    if (scene.disabled) return;

    const mk = (type, gainVal, filter) => {
      const src = loopNode(type);
      if (!src) return null;
      const g = c.createGain();
      g.gain.value = gainVal * gain;
      let node = src;
      if (filter) {
        const f = c.createBiquadFilter();
        f.type = filter.type;
        f.frequency.value = filter.freq;
        node.connect(f);
        node = f;
      }
      node.connect(g);
      g.connect(master);
      src.start();
      sceneNodes.push(src, g);
    };

    if (id === 'rain') {
      mk('white', 0.35, { type: 'highpass', freq: 500 });
      const droplet = shortNoiseBuffer(c, 0.1);
      const t = setInterval(() => {
        if (!droplet) return;
        const src = c.createBufferSource();
        src.buffer = droplet;
        const f = c.createBiquadFilter();
        f.type = 'bandpass';
        f.frequency.value = 1800 + Math.random() * 2400;
        f.Q.value = 8;
        const g = c.createGain();
        g.gain.setValueAtTime((0.04 + Math.random() * 0.16) * gain, c.currentTime);
        g.gain.exponentialRampToValueAtTime(0.001, c.currentTime + 0.05);
        src.connect(f); f.connect(g); g.connect(master);
        src.start(c.currentTime);
        src.stop(c.currentTime + 0.06);
        sceneNodes.push(src, g);
      }, 110);
      sceneTimers.push(t);
    } else if (id === 'fireplace') {
      mk('brown', 0.55, { type: 'lowpass', freq: 700 });
      const crackle = shortNoiseBuffer(c, 0.08);
      const t = setInterval(() => {
        if (Math.random() > 0.55 || !crackle) return;
        const src = c.createBufferSource();
        src.buffer = crackle;
        const f = c.createBiquadFilter();
        f.type = 'highpass';
        f.frequency.value = 1600 + Math.random() * 1800;
        const g = c.createGain();
        const peak = (0.05 + Math.random() * 0.2) * gain;
        g.gain.setValueAtTime(0, c.currentTime);
        g.gain.linearRampToValueAtTime(peak, c.currentTime + 0.015);
        g.gain.exponentialRampToValueAtTime(0.001, c.currentTime + 0.09);
        src.connect(f); f.connect(g); g.connect(master);
        src.start(c.currentTime);
        src.stop(c.currentTime + 0.1);
        sceneNodes.push(src, g);
      }, 160);
      sceneTimers.push(t);
    } else if (id === 'library') {
      mk('pink', 0.4, { type: 'lowpass', freq: 900 });
    } else {
      mk(id === 'white-noise' ? 'white' : id === 'brown-noise' ? 'brown' : 'pink', 0.55, null);
    }
  }

  /** 场景是否可用：自定义声音需已上传音频 */
  function sceneUsable(id) {
    if (id === 'custom') {
      return !!(store.state.settings.focus && store.state.settings.focus.customAudio);
    }
    const s = SCENES.find((x) => x.id === id);
    return !!s && !s.disabled;
  }

  function playCustomAudio(gain) {
    stopCustomAudio();
    const ca = store.state.settings.focus && store.state.settings.focus.customAudio;
    if (!ca || !ca.dataUrl) return;
    try {
      const el = new Audio(ca.dataUrl);
      el.loop = true;
      el.volume = Math.max(0, Math.min(1, gain || 0.6));
      el.play().catch(() => { /* 无音频设备时静默 */ });
      customAudioEl = el;
    } catch (e) { /* 忽略 */ }
  }

  function stopCustomAudio() {
    if (customAudioEl) {
      try { customAudioEl.pause(); } catch (e) { /* 忽略 */ }
      customAudioEl = null;
    }
    customRole = null;
  }

  /** 播放主场景 + 可选叠加场景（Noisli 式混音，v0.17.0；自定义声音 v0.18.0） */
  function startScene(id) {
    stopScene();
    stopCustomAudio();
    const focus = store.state.settings.focus || {};
    const base = focus.volume == null ? 0.6 : focus.volume;
    if (id === 'custom') {
      playCustomAudio(base);
      customRole = 'primary';
    } else {
      buildScene(id, base);
    }
    const mix = focus.mixSceneId;
    if (mix && mix !== id && sceneUsable(mix)) {
      const mv = (focus.mixVolume == null ? 0.4 : focus.mixVolume) * base;
      if (mix === 'custom') {
        playCustomAudio(mv);
        customRole = 'mix';
      } else {
        buildScene(mix, mv);
      }
    }
  }

  /** 短噪声缓冲（雨滴 / 火星），避免高频创建长缓冲 */
  function shortNoiseBuffer(c, seconds) {
    try {
      const len = Math.max(1, Math.floor(c.sampleRate * seconds));
      const buf = c.createBuffer(1, len, c.sampleRate);
      const d = buf.getChannelData(0);
      for (let i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;
      return buf;
    } catch (e) {
      return null;
    }
  }

  function stopScene() {
    sceneNodes.forEach((n) => {
      try { if (n.stop) n.stop(); } catch (e) { /* 已停止 */ }
      try { n.disconnect(); } catch (e) { /* 忽略 */ }
    });
    sceneNodes = [];
    sceneTimers.forEach((t) => clearInterval(t));
    sceneTimers = [];
  }

  function beep() {
    const c = ensureCtx();
    if (!c) return;
    const osc = c.createOscillator();
    const g = c.createGain();
    osc.type = 'sine';
    osc.frequency.value = 880;
    g.gain.setValueAtTime(0.18, c.currentTime);
    g.gain.exponentialRampToValueAtTime(0.001, c.currentTime + 0.5);
    osc.connect(g); g.connect(master);
    osc.start();
    osc.stop(c.currentTime + 0.5);
  }

  /* ---------- 番茄钟状态机 ---------- */
  const F = {
    overlay: null,
    page: false,      // S12：以底部导航「专注」页呈现（不销毁容器）
    timer: null,
    mode: 'focus',      // focus | shortBreak | longBreak
    seconds: 0,
    total: 0,
    running: false,
    taskId: null,
    round: 0,           // 本轮已完成的番茄数
    startedAt: null,
    scenePanel: false,
    breath: false,
    _title: document.title
  };

  function pomo() {
    return Object.assign({
      focusMin: 25, shortBreakMin: 5, longBreakMin: 15,
      roundsBeforeLongBreak: 4, autoStartBreak: false, autoStartFocus: false, soundOnFinish: true
    }, store.state.settings.pomodoro || {});
  }

  function setDuration(mode) {
    const p = pomo();
    F.total = (mode === 'focus' ? p.focusMin : mode === 'shortBreak' ? p.shortBreakMin : p.longBreakMin) * 60;
    F.seconds = F.total;
  }

  function open(taskId) {
    close();
    F.page = false;
    F.taskId = taskId || null;
    F.mode = 'focus';
    F.round = 0;
    setDuration('focus');
    renderOverlay();
    const sceneId = (store.state.settings.focus && store.state.settings.focus.sceneId) || 'pink-noise';
    startScene(sceneId);
  }

  function toggleBreath(on) {
    F.breath = on == null ? !F.breath : on;
    if (F.overlay) {
      const el = F.overlay.querySelector('.focus-breath');
      if (el) el.classList.toggle('on', F.breath);
      const btn = F.overlay.querySelector('[data-focus="breath"]');
      if (btn) btn.classList.toggle('active', F.breath);
    }
  }

  function close() {
    stopTimer();
    stopScene();
    stopCustomAudio();
    if (F.page) {
      setDuration('focus');
      if (F.overlay) updateUi();
      F.overlay = null;
      return;
    }
    F.overlay = null;
    document.title = F._title;
    const root = document.getElementById('focus-root');
    if (root) root.remove();
  }

  /** 今日专注统计（分钟 + 番茄），供页面顶部展示 */
  function todayStatsHtml() {
    const now = new Date();
    const today = now.getFullYear() + '-' + String(now.getMonth() + 1).padStart(2, '0') + '-' + String(now.getDate()).padStart(2, '0');
    let minutes = 0, tomatoes = 0;
    (store.state.focusSessions || []).forEach((s) => {
      const end = s.endAt ? new Date(s.endAt) : null;
      if (end && (end.getFullYear() + '-' + String(end.getMonth() + 1).padStart(2, '0') + '-' + String(end.getDate()).padStart(2, '0')) === today) {
        minutes += s.minutes || 0;
        if (s.completed) tomatoes++;
      }
    });
    return '<div class="focus-stats">' +
      '<span class="focus-stat">' + S.icons.icon('clock', 12) + ' 今日 ' + minutes + ' 分钟</span>' +
      '<span class="focus-stat">' + S.icons.icon('candy', 12) + ' ' + tomatoes + ' 番茄</span>' +
      '</div>';
  }

  /** S12：底部导航「专注」页渲染（复用浮层状态机，场景面板常显） */
  function render(box) {
    stopScene();
    stopCustomAudio();
    F.page = true;
    if (!F.timer && !F.startedAt) {
      F.taskId = null;
      F.mode = 'focus';
      F.round = 0;
      setDuration('focus');
    }
    const sceneId = (store.state.settings.focus && store.state.settings.focus.sceneId) || 'pink-noise';
    const scene = SCENES.find((s) => s.id === sceneId) || SCENES[0];
    const root = document.createElement('div');
    root.className = 'focus-overlay focus-page';
    root.style.cssText = '--scene-a:' + scene.grad[0] + ';--scene-b:' + scene.grad[1];
    F.scenePanel = true;
    root.innerHTML =
      '<div class="focus-top">' +
      '<span class="focus-brand">' + S.icons.icon('bolt', 16) + ' 专注</span>' +
      todayStatsHtml() +
      '<div class="focus-top-actions">' +
      '<button class="icon-btn" data-focus="scene" title="专注场景">' + S.icons.icon('music', 15) + '</button>' +
      '</div></div>' +
      '<div class="focus-main">' +
      '<div class="focus-card focus-card-timer">' +
      '<div class="focus-card-head"><span class="head-ico">' + S.icons.icon('bolt', 14) + '</span> 番茄钟</div>' +
      '<div class="focus-breath"></div>' +
      '<div class="focus-ring-wrap">' +
      '<svg viewBox="0 0 240 240">' +
      '<circle class="focus-ring-bg" cx="120" cy="120" r="110"/>' +
      '<circle class="focus-ring-fg" cx="120" cy="120" r="110"/>' +
      '</svg>' +
      '<div class="focus-ring-text"><b id="focus-time">' + fmtTime(F.seconds) + '</b>' +
      '<span id="focus-mode-label" class="mode-focus">专注</span></div>' +
      '</div>' +
      (F.taskId
        ? '<div class="focus-task">关联任务：' + util.escapeHtml(F.taskId) + '</div>'
        : '<div class="focus-task">自由专注 · 从任务卡进入可关联作业</div>') +
      '<div class="focus-round" id="focus-round">第 ' + F.round + '/4 轮番茄</div>' +
      '<div class="focus-controls">' +
      '<button class="btn primary" id="focus-start" data-focus="start">' + S.icons.icon('bolt', 14) + ' 开始</button>' +
      '<button class="btn" id="focus-pause" data-focus="pause" hidden>' + S.icons.icon('pause', 14) + ' 暂停</button>' +
      '<button class="btn" data-focus="skip">' + S.icons.icon('chevron-right', 14) + ' 跳过</button>' +
      '<button class="btn soft-danger" data-focus="end">' + S.icons.icon('close', 14) + ' 结束</button>' +
      '</div>' +
      '<div class="focus-scene-row">' +
      '<span class="scene-current">' + S.icons.icon(scene.icon, 14) + ' ' + util.escapeHtml(scene.name) + '</span>' +
      '<span class="vol-label">' + S.icons.icon('bell', 13) + '</span>' +
      '<input type="range" id="focus-volume" min="0" max="100" value="' + Math.round(((store.state.settings.focus && store.state.settings.focus.volume) || 0.6) * 100) + '">' +
      '<button class="icon-btn breath-btn" data-focus="breath" title="呼吸引导">' + S.icons.icon('target', 15) + '</button>' +
      '</div>' +
      '</div>' +
      '<div class="focus-card focus-card-scene">' +
      '<div class="focus-card-head"><span class="head-ico">' + S.icons.icon('music', 14) + '</span> 环境与噪音' +
      '<span class="focus-card-sub">选择环境 · 背景氛围与白噪音同步切换</span></div>' +
      '<div class="focus-scene-panel" id="focus-scene-panel">' + sceneHtml() + mixRowHtml() + customAudioRowHtml() + '</div>' +
      '</div>' +
      '</div>';
    box.innerHTML = '';
    box.appendChild(root);
    F.overlay = root;
    bindOverlay(root);
    updateUi();
    startScene(sceneId);
  }

  function stopTimer() {
    if (F.timer) { clearInterval(F.timer); F.timer = null; }
    F.running = false;
  }

  function start() {
    if (F.timer || F.seconds <= 0) return;
    F.running = true;
    if (!F.startedAt) F.startedAt = new Date();
    F.timer = setInterval(tick, 1000);
    updateUi();
  }

  function pause() {
    stopTimer();
    updateUi();
  }

  function skip() {
    if (F.mode === 'focus') {
      // 跳过专注段：不记录，回到专注就绪
      stopTimer();
      F.startedAt = null;
      setDuration('focus');
      updateUi();
      S.ui.toast('已跳过本轮专注（未记录）');
      return;
    }
    completeSegment();
  }

  function tick() {
    F.seconds--;
    if (F.seconds <= 0) {
      completeSegment();
      return;
    }
    updateUi();
  }

  function completeSegment() {
    stopTimer();
    if (F.mode === 'focus') {
      const minutes = Math.max(1, Math.round(F.total / 60));
      const task = F.taskId ? store.state.tasks.find((t) => t.id === F.taskId) : null;
      store.addFocusSession({
        taskId: F.taskId,
        subject: task ? task.subject : null,
        sceneId: (store.state.settings.focus && store.state.settings.focus.sceneId) || null,
        startAt: F.startedAt ? F.startedAt.toISOString() : new Date().toISOString(),
        endAt: new Date().toISOString(),
        minutes,
        completed: true,
        source: 'pomodoro'
      });
      F.round++;
      sugarBurst();
      if ((store.state.settings.pomodoro || {}).soundOnFinish !== false) beep();
      S.ui.toast('专注完成！收获 1 颗糖果');
      const p = pomo();
      if (p.autoStartBreak) {
        F.mode = F.round % p.roundsBeforeLongBreak === 0 ? 'longBreak' : 'shortBreak';
        setDuration(F.mode);
        F.startedAt = null;
        start();
        return;
      }
    }
    const p = pomo();
    if (F.mode === 'shortBreak' || F.mode === 'longBreak') {
      if (p.autoStartFocus) {
        F.mode = 'focus';
        setDuration('focus');
        F.startedAt = null;
        start();
        return;
      }
      F.mode = 'focus';
      setDuration('focus');
      F.startedAt = null;
    } else {
      F.mode = F.round % p.roundsBeforeLongBreak === 0 ? 'longBreak' : 'shortBreak';
      setDuration(F.mode);
      F.startedAt = null;
    }
    updateUi();
  }

  function sugarBurst() {
    const colors = ['var(--pink-strong)', 'var(--mint-strong)', 'var(--lavender-strong)', 'var(--yellow-strong)', 'var(--peach-strong)'];
    for (let i = 0; i < 26; i++) {
      const el = document.createElement('i');
      el.className = 'confetti-piece';
      const size = 6 + Math.random() * 8;
      el.style.cssText =
        'left:' + (Math.random() * 100) + 'vw;' +
        'width:' + size + 'px;height:' + (size * (0.6 + Math.random())) + 'px;' +
        'background:' + colors[i % colors.length] + ';' +
        'animation-duration:' + (1.2 + Math.random() * 1.4) + 's;' +
        'animation-delay:' + (Math.random() * 0.3) + 's;' +
        'border-radius:' + (Math.random() > 0.5 ? '50%' : '3px');
      document.body.appendChild(el);
      setTimeout(() => el.remove(), 3200);
    }
  }

  function fmtTime(s) {
    const m = Math.floor(s / 60);
    const ss = s % 60;
    return String(m).padStart(2, '0') + ':' + String(ss).padStart(2, '0');
  }

  function modeLabel() {
    return F.mode === 'focus' ? '专注' : F.mode === 'shortBreak' ? '短休' : '长休';
  }

  function updateUi() {
    if (!F.overlay) return;
    const p = pomo();
    const timeEl = F.overlay.querySelector('#focus-time');
    const ring = F.overlay.querySelector('.focus-ring-fg');
    const label = F.overlay.querySelector('#focus-mode-label');
    const roundEl = F.overlay.querySelector('#focus-round');
    const startBtn = F.overlay.querySelector('#focus-start');
    const pauseBtn = F.overlay.querySelector('#focus-pause');
    if (timeEl) timeEl.textContent = fmtTime(F.seconds);
    if (label) {
      label.textContent = modeLabel();
      label.className = F.mode === 'focus' ? 'mode-focus' : 'mode-break';
    }
    if (ring) {
      const r = 110;
      const c = 2 * Math.PI * r;
      ring.style.strokeDashoffset = (c * (1 - F.seconds / Math.max(1, F.total))).toFixed(1);
    }
    if (roundEl) roundEl.textContent = '第 ' + F.round + '/' + (p.roundsBeforeLongBreak || 4) + ' 轮番茄';
    if (startBtn) startBtn.hidden = F.running;
    if (pauseBtn) pauseBtn.hidden = !F.running;
    document.title = F.running ? fmtTime(F.seconds) + ' · ' + modeLabel() + ' · 糖纸' : F._title;
  }

  function sceneHtml() {
    const current = (store.state.settings.focus && store.state.settings.focus.sceneId) || 'pink-noise';
    const custom = store.state.settings.focus && store.state.settings.focus.customAudio;
    return SCENES
      .filter((s) => !(s.custom && !custom))
      .map((s) => {
        const usable = sceneUsable(s.id);
        const hint = s.custom ? '上传音频后可用' : (s.hint || '');
        return '<button class="scene-card' + (s.id === current ? ' active' : '') + '" data-scene="' + s.id + '"' + (usable ? '' : ' disabled') +
      ' style="--scene-a:' + s.grad[0] + ';--scene-b:' + s.grad[1] + '">' +
      '<span class="scene-emoji">' + S.icons.icon(s.icon, 24) + '</span>' +
      '<span class="scene-name">' + (s.custom && custom ? util.escapeHtml(custom.name) : util.escapeHtml(s.name)) + '</span>' +
      (usable ? '' : '<span class="scene-hint">' + util.escapeHtml(hint) + '</span>') +
      '</button>';
      }).join('');
  }

  function mixRowHtml() {
    const focus = store.state.settings.focus || {};
    const options = ['<option value="">无（不叠加）</option>'].concat(
      SCENES.filter((s) => sceneUsable(s.id)).map((s) => {
        const name = s.custom && focus.customAudio ? focus.customAudio.name : s.name;
        return '<option value="' + s.id + '"' + (focus.mixSceneId === s.id ? ' selected' : '') + '>' +
          util.escapeHtml(name) + '</option>';
      })
    ).join('');
    return '<div class="mix-row">' +
      '<span class="mix-label">' + S.icons.icon('music', 13) + ' 叠加音</span>' +
      '<select id="focus-mix">' + options + '</select>' +
      '<span class="vol-label">' + S.icons.icon('bell', 13) + '</span>' +
      '<input type="range" id="focus-mix-volume" min="0" max="100" value="' +
      Math.round(((focus.mixVolume == null ? 0.4 : focus.mixVolume)) * 100) + '">' +
      '</div>';
  }

  function customAudioRowHtml() {
    const ca = store.state.settings.focus && store.state.settings.focus.customAudio;
    if (ca) {
      return '<div class="mix-row"><span class="mix-label">' + S.icons.icon('music', 13) + ' ' + util.escapeHtml(ca.name) + '</span>' +
        '<button class="btn small soft-danger" data-focus="remove-custom">删除</button></div>';
    }
    return '<div class="mix-row"><span class="mix-label">' + S.icons.icon('upload', 13) + ' 自定义声音</span>' +
      '<label class="btn small" for="custom-audio-file">上传音频（≤2MB）</label>' +
      '<input type="file" id="custom-audio-file" accept="audio/*" hidden></div>';
  }

  function renderOverlay() {
    const sceneId = (store.state.settings.focus && store.state.settings.focus.sceneId) || 'pink-noise';
    const scene = SCENES.find((s) => s.id === sceneId) || SCENES[0];
    const task = F.taskId ? store.state.tasks.find((t) => t.id === F.taskId) : null;
    const color = task ? store.getSubjectColor(task.subject) : 'var(--pink)';
    const root = document.createElement('div');
    root.className = 'focus-overlay';
    root.id = 'focus-root';
    root.style.cssText = '--scene-a:' + scene.grad[0] + ';--scene-b:' + scene.grad[1] + ';--task-color:' + color;
    root.innerHTML =
      '<div class="focus-top">' +
      '<span class="focus-brand">' + S.icons.icon('clock', 16) + ' 番茄钟</span>' +
      '<div class="focus-top-actions">' +
      '<button class="icon-btn" data-focus="scene" title="专注场景">' + S.icons.icon('music', 15) + '</button>' +
      '<button class="icon-btn" data-focus="close" title="结束并关闭 (Esc)">' + S.icons.icon('close', 15) + '</button>' +
      '</div></div>' +
      '<div class="focus-main">' +
      '<div class="focus-breath"></div>' +
      '<div class="focus-ring-wrap">' +
      '<svg viewBox="0 0 240 240">' +
      '<circle class="focus-ring-bg" cx="120" cy="120" r="110"/>' +
      '<circle class="focus-ring-fg" cx="120" cy="120" r="110"/>' +
      '</svg>' +
      '<div class="focus-ring-text"><b id="focus-time">' + fmtTime(F.seconds) + '</b>' +
      '<span id="focus-mode-label" class="mode-focus">专注</span></div>' +
      '</div>' +
      (task
        ? '<div class="focus-task" style="--task-color:' + color + '">' +
          '<span class="task-subject-badge">' + util.escapeHtml(task.subject) + '</span>' +
          '<span class="focus-task-title">' + util.escapeHtml(task.title) + '</span></div>'
        : '<div class="focus-task">自由专注 · 未关联任务</div>') +
      '<div class="focus-round" id="focus-round">第 0/4 轮番茄</div>' +
      '<div class="focus-controls">' +
      '<button class="btn primary" id="focus-start" data-focus="start">' + S.icons.icon('bolt', 14) + ' 开始</button>' +
      '<button class="btn" id="focus-pause" data-focus="pause" hidden>' + S.icons.icon('pause', 14) + ' 暂停</button>' +
      '<button class="btn" data-focus="skip">' + S.icons.icon('chevron-right', 14) + ' 跳过</button>' +
      '<button class="btn soft-danger" data-focus="end">' + S.icons.icon('close', 14) + ' 结束</button>' +
      '</div>' +
      '<div class="focus-scene-row">' +
      '<span class="scene-current">' + S.icons.icon(scene.icon, 14) + ' ' + util.escapeHtml(scene.name) + '</span>' +
      '<span class="vol-label">' + S.icons.icon('bell', 13) + '</span>' +
      '<input type="range" id="focus-volume" min="0" max="100" value="' + Math.round(((store.state.settings.focus && store.state.settings.focus.volume) || 0.6) * 100) + '">' +
      '<button class="icon-btn breath-btn" data-focus="breath" title="呼吸引导">' + S.icons.icon('target', 15) + '</button>' +
      '</div>' +
      '<div class="focus-scene-panel" id="focus-scene-panel" hidden>' + sceneHtml() + mixRowHtml() + customAudioRowHtml() + '</div>' +
      '</div>';
    document.body.appendChild(root);
    F.overlay = root;
    bindOverlay(root);
    updateUi();
  }

  function bindOverlay(root) {
    root.addEventListener('click', (e) => {
      const btn = e.target.closest('[data-focus]');
      if (btn) {
        const a = btn.dataset.focus;
        if (a === 'start') start();
        else if (a === 'pause') pause();
        else if (a === 'skip') skip();
        else if (a === 'end') close();
        else if (a === 'breath') toggleBreath();
        else if (a === 'remove-custom') {
          store.updateSettings({ focus: Object.assign({}, store.state.settings.focus, { customAudio: null }) });
          startScene((store.state.settings.focus && store.state.settings.focus.sceneId) || 'pink-noise');
          refreshScenePanel(root);
          return;
        }
        else if (a === 'scene') {
          F.scenePanel = !F.scenePanel;
          const panel = root.querySelector('#focus-scene-panel');
          if (panel) panel.hidden = !F.scenePanel;
        } else if (a === 'close') close();
        return;
      }
      const sc = e.target.closest('[data-scene]');
      if (sc && !sc.disabled) {
        store.updateSettings({ focus: Object.assign({}, store.state.settings.focus, { sceneId: sc.dataset.scene }) });
        const scene = SCENES.find((s) => s.id === sc.dataset.scene);
        const cur = root.querySelector('.scene-current');
        if (cur && scene) cur.innerHTML = S.icons.icon(scene.icon, 14) + ' ' + scene.name;
        // 环境背景氛围随场景切换（S12，对齐安卓版）
        if (scene && scene.grad) {
          root.style.setProperty('--scene-a', scene.grad[0]);
          root.style.setProperty('--scene-b', scene.grad[1]);
        }
        root.querySelectorAll('.scene-card').forEach((c) => c.classList.toggle('active', c.dataset.scene === sc.dataset.scene));
        startScene(sc.dataset.scene);
      }
    });
    bindPanelControls(root);
    const vol = root.querySelector('#focus-volume');
    if (vol) {
      vol.addEventListener('input', () => {
        const v = Number(vol.value) / 100;
        const focus = Object.assign({}, store.state.settings.focus, { volume: v });
        store.updateSettings({ focus });
        if (master) master.gain.value = v;
        if (customAudioEl) {
          customAudioEl.volume = customRole === 'mix'
            ? v * (focus.mixVolume == null ? 0.4 : focus.mixVolume)
            : v;
        }
      });
    }
    root.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && !F.page) close();
    });
    root.setAttribute('tabindex', '-1');
    root.focus();
  }

  /** 绑定场景面板内的控件（混音选择/音量/自定义音频上传）；面板刷新后重新调用 */
  function bindPanelControls(root) {
    const mixSel = root.querySelector('#focus-mix');
    if (mixSel) {
      mixSel.addEventListener('change', () => {
        store.updateSettings({ focus: Object.assign({}, store.state.settings.focus, { mixSceneId: mixSel.value || null }) });
        startScene((store.state.settings.focus && store.state.settings.focus.sceneId) || 'pink-noise');
      });
    }
    const mixVol = root.querySelector('#focus-mix-volume');
    if (mixVol) {
      mixVol.addEventListener('input', () => {
        store.updateSettings({ focus: Object.assign({}, store.state.settings.focus, { mixVolume: Number(mixVol.value) / 100 }) });
        startScene((store.state.settings.focus && store.state.settings.focus.sceneId) || 'pink-noise');
      });
    }
    const file = root.querySelector('#custom-audio-file');
    if (file) {
      file.addEventListener('change', () => {
        const f = file.files && file.files[0];
        file.value = '';
        if (!f) return;
        if (!/^audio\//.test(f.type)) { S.ui.toast('请选择音频文件'); return; }
        if (f.size > 2 * 1024 * 1024) { S.ui.toast('音频需小于 2MB'); return; }
        const reader = new FileReader();
        reader.onload = () => {
          store.updateSettings({
            focus: Object.assign({}, store.state.settings.focus, {
              customAudio: { name: f.name, dataUrl: reader.result }
            })
          });
          S.ui.toast('自定义声音已添加');
          startScene((store.state.settings.focus && store.state.settings.focus.sceneId) || 'pink-noise');
          refreshScenePanel(root);
        };
        reader.readAsDataURL(f);
      });
    }
  }

  /** 刷新场景面板内容（上传/删除自定义声音后） */
  function refreshScenePanel(root) {
    const panel = root.querySelector('#focus-scene-panel');
    if (panel) {
      panel.innerHTML = sceneHtml() + mixRowHtml() + customAudioRowHtml();
      bindPanelControls(root);
    }
  }

  g.Sugar = g.Sugar || {};
  g.Sugar.ui = g.Sugar.ui || {};
  g.Sugar.ui.focus = { open, close, render, SCENES, toggleBreath, isOpen: () => !!F.overlay };
})(typeof window !== 'undefined' ? window : globalThis);
