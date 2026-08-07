/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 应用主控制器 */
(function (g) {
  'use strict';

  const S = g.Sugar;
  const util = S.util;
  const store = S.store;

  const TABS = [
    { id: 'home', icon: 'home', label: '首页' },
    { id: 'notes', icon: 'file-text', label: '便签' },
    { id: 'focus', icon: 'bolt', label: '专注' },
    { id: 'calendar', icon: 'calendar', label: '日历' },
    { id: 'stats', icon: 'chart-bar', label: '统计' },
    { id: 'settings', icon: 'user', label: '我的' }
  ];
  const VIEW_ORDER = ['home', 'notes', 'focus', 'calendar', 'stats', 'settings'];

  const App = {
    state: {
      view: 'home',
      query: '',
      subject: '全部',
      priority: 'all',
      calMode: 'month',
      calSelected: util.todayStr(),
      statsRange: 'week',
      noteTag: '全部',
      showArchivedNotes: false
    },

    init() {
      // v0.28.0：首次打开必须阅读并同意《用户协议》《隐私政策》后才能进入应用
      if (S.legal && !S.legal.isAgreed()) {
        S.legal.showGate();
        return;
      }
      this.applyPrefs();
      store.subscribe(() => {
        this.applyPrefs();
        // 设置页控件操作期间静默：只刷新主题/顶栏，不重建视图（避免整页闪屏与开关跳动）
        if (this._suspendView) {
          this.renderChrome();
        } else {
          this.render();
        }
        if (S.sync && typeof S.sync.scheduleSync === 'function') S.sync.scheduleSync();
      });
      this.bindGlobalEvents();
      this.initReveal();
      this.bindScrollEffects();
      S.reminders.init();
      this.render();
      // 后台测量实际刷新率，供「跟随系统」档位使用
      this.detectFps().then((fps) => {
        this._detectedFps = fps;
        this.applyPrefs();
      });
    },

    applyPrefs() {
      const set = store.state.settings;
      const theme = set.theme || 'classic';
      const isDark = theme === 'dark';
      document.documentElement.dataset.theme = isDark ? 'dark' : 'light';
      document.documentElement.dataset.palette = isDark ? 'classic' : theme;
      // v0.29.0：移除「动态动画」开关，动画默认全程开启（兼容旧数据不再关闭）
      document.documentElement.dataset.fps = this.resolveFps();
      const meta = document.querySelector('meta[name="theme-color"]');
      if (meta) meta.setAttribute('content', isDark ? '#231D2B' : '#FBF6F2');
    },

    resolveFps() {
      const v = store.state.settings.frameRate;
      if (v && v !== 'auto') return v;
      return String(this._detectedFps || 60);
    },

    /**
     * 测量实际显示帧率（rAF 采样 1.8s 取中位数，归入 60/90/120/144 档）
     * @returns {Promise<number>}
     */
    detectFps() {
      return new Promise((resolve) => {
        const samples = [];
        let last = performance.now();
        const start = last;
        const tick = (now) => {
          const dt = now - last;
          last = now;
          if (dt > 0 && dt < 120) samples.push(1000 / dt);
          if (now - start < 1800) {
            requestAnimationFrame(tick);
          } else {
            samples.sort((a, b) => a - b);
            const med = samples[Math.floor(samples.length / 2)] || 60;
            const fps = Math.round(med);
            const buckets = [60, 90, 120, 144];
            resolve(buckets.reduce((best, b) => (Math.abs(b - fps) < Math.abs(best - fps) ? b : best), 60));
          }
        };
        requestAnimationFrame(tick);
      });
    },

    navigate(view) {
      const prev = this.state.view;
      this.state.view = view;
      this.renderChrome();
      this.renderView(prev);
    },

    render() {
      this.renderChrome();
      this.renderView();
      this.renderRightPanel();
    },

    renderChrome() {
      const topbar = document.getElementById('topbar');
      const tasks = store.state.tasks.filter((t) => !t.isDeleted);
      const done = tasks.filter((t) => t.isCompleted).length;
      const rate = tasks.length ? Math.round((done / tasks.length) * 100) : 0;

      topbar.innerHTML =
        '<div class="brand"><img class="brand-logo" src="icon.svg" alt="糖纸"><span>糖纸</span></div>' +
        '<div class="spacer"></div>' +
        '<div class="search-box wide-search"><span class="s-icon">' + S.icons.icon('search', 14) + '</span>' +
        '<input id="global-search" placeholder="搜索作业..." value="' + util.escapeHtml(this.state.query) + '"></div>' +
        '<div class="progress-pill"><div class="bar"><i style="width:' + rate + '%"></i></div>' +
        '<span>' + rate + '% · ' + done + '/' + tasks.length + '</span></div>' +
        '<button class="icon-btn primary" data-nav="import" title="粘贴导入 (Ctrl+N)">' + S.icons.icon('plus', 18) + '</button>' +
        '<button class="icon-btn" data-nav="settings" title="我的">' + util.avatarHtml(store.state.settings.avatar, 'avatar-sm') + '</button>';

      const topTabs = document.getElementById('top-tabs');
      topTabs.hidden = false;
      topTabs.innerHTML = TABS.map((t) =>
        '<button data-nav="' + t.id + '"' + (this.state.view === t.id ? ' class="active"' : '') + '>' +
        S.icons.icon(t.icon, 15) + ' ' + t.label + '</button>').join('');

      const sidebar = document.getElementById('sidebar');
      sidebar.innerHTML = this.sidebarHtml();

      const bottomNav = document.getElementById('bottom-nav');
      bottomNav.innerHTML = TABS.map((t) =>
        '<button data-nav="' + t.id + '"' + (this.state.view === t.id ? ' class="active"' : '') + '>' +
        '<span class="nav-emoji">' + S.icons.icon(t.icon, 18) + '</span>' + t.label + '</button>').join('');
    },

    sidebarHtml() {
      const tasks = store.state.tasks.filter((t) => !t.isDeleted);
      const counts = {};
      tasks.forEach((t) => { counts[t.subject] = (counts[t.subject] || 0) + 1; });
      const nav = TABS.map((t) =>
        '<button data-nav="' + t.id + '"' + (this.state.view === t.id ? ' class="active"' : '') + '>' +
        '<span class="nav-emoji">' + S.icons.icon(t.icon, 18) + '</span>' + t.label + '</button>').join('');
      const subjects = store.state.subjects.filter((s) => s.enabled).map((s) =>
        '<button data-subject="' + util.escapeHtml(s.name) + '"' + (this.state.subject === s.name ? ' class="active"' : '') + '>' +
        '<span class="dot" style="background:' + s.color + '"></span>' + util.escapeHtml(s.name) +
        '<span class="cnt">' + (counts[s.name] || 0) + '</span></button>').join('');
      return '<div class="side-nav">' + nav + '</div>' +
        '<div class="side-section-title">科目</div>' +
        '<div class="side-subjects">' +
        '<button data-subject="全部"' + (this.state.subject === '全部' ? ' class="active"' : '') + '>' +
        '<span class="dot" style="background:linear-gradient(135deg,var(--pink),var(--mint))"></span>全部<span class="cnt">' + tasks.length + '</span></button>' +
        subjects + '</div>';
    },

    renderRightPanel() {
      const panel = document.getElementById('right-panel');
      const s = S.stats.compute(store.state, 'week');
      const bars = s.dailyTrend.slice(-7).map((d) =>
        '<i style="height:' + Math.max(4, (d.count / Math.max(1, Math.max(...s.dailyTrend.map((x) => x.count)))) * 100) + '%;' +
        (d.isToday ? 'background:var(--mint-strong)' : '') + '" title="' + d.label + '：' + d.count + '"></i>').join('');
      panel.innerHTML =
        '<div class="mini-card"><h4>' + S.icons.icon('chart-line', 14) + ' 本周完成率</h4><div class="mini-ring">' +
        ringSvg(s.rate, 'ringGradMini') +
        '<div class="ring-text" style="position:relative"><b>' + s.rate + '%</b></div></div>' +
        '<div style="font-size:11px;color:var(--text-3);margin-top:6px">完成 ' + s.completed + '/' + s.total + ' 项</div></div>' +
        '<div class="mini-card"><h4>' + S.icons.icon('chart-bar', 14) + ' 近 7 天完成量</h4><div class="mini-bars">' + bars + '</div></div>' +
        '<div class="mini-card"><h4>' + S.icons.icon('flame', 14) + ' 连续完成</h4><div style="font-size:20px;font-weight:800">' + s.streak + ' 天</div></div>' +
        '<div class="mini-card"><h4>' + S.icons.icon('clock', 14) + ' 今日专注</h4>' +
        '<div style="font-size:20px;font-weight:800">' + s.focusTodayMinutes + ' 分钟</div>' +
        '<div style="font-size:11px;color:var(--text-3);margin-top:4px">' + s.focusTodayCount + ' 个番茄 · 本周 ' + s.focusWeekMinutes + ' 分钟</div></div>';
    },

    renderView(prev) {
      const wrap = document.getElementById('view-wrap');
      const wide = document.getElementById('global-search');
      if (wide) wide.value = this.state.query;
      // 方向感知页面过渡：前进右滑入 / 后退左滑入 / 无前序不上方向动画
      const dir = transitionDir(prev, this.state.view);
      wrap.classList.remove('view-enter-up', 'view-enter-left', 'view-enter-right');
      if (dir) {
        void wrap.offsetWidth; // 强制 reflow 以重触发动画
        wrap.classList.add('view-enter-' + dir);
      }
      // 每次渲染使用全新子容器：避免常驻 wrap 上的事件监听器重复叠加
      const box = document.createElement('div');
      box.className = 'view-box';
      wrap.innerHTML = '';
      wrap.appendChild(box);
      if (this.state.view === 'home') S.ui.home.render(box);
      else if (this.state.view === 'notes') S.ui.notes.render(box);
      else if (this.state.view === 'focus') S.ui.focus.render(box);
      else if (this.state.view === 'calendar') S.ui.calendar.render(box);
      else if (this.state.view === 'stats') S.ui.stats.render(box);
      else if (this.state.view === 'settings') S.ui.settings.render(box);
      this.observeReveals(box);
    },

    initReveal() {
      if (!('IntersectionObserver' in window)) {
        this._io = null;
        return;
      }
      this._io = new IntersectionObserver((entries) => {
        entries.forEach((en) => {
          en.target.classList.toggle('reveal-in', en.isIntersecting);
        });
      }, { threshold: 0.08, rootMargin: '0px 0px -6% 0px' });
    },

    observeReveals(root) {
      const els = root ? root.querySelectorAll('.reveal:not(.observed)') : document.querySelectorAll('.reveal:not(.observed)');
      if (!this._io) {
        els.forEach((el) => el.classList.add('reveal-in'));
        return;
      }
      els.forEach((el) => {
        el.classList.add('observed');
        this._io.observe(el);
      });
    },

    bindScrollEffects() {
      const topbar = document.getElementById('topbar');
      const onScroll = () => {
        topbar.classList.toggle('scrolled', window.scrollY > 6);
      };
      window.addEventListener('scroll', onScroll, { passive: true });
      onScroll();
    },

    bindGlobalEvents() {
      document.addEventListener('click', (e) => {
        const navBtn = e.target.closest('[data-nav]');
        if (!navBtn) return;
        const nav = navBtn.dataset.nav;
        if (nav === 'import') { S.ui.modal.openImport(); return; }
        this.navigate(nav);
      });
      document.addEventListener('click', (e) => {
        const subBtn = e.target.closest('#sidebar [data-subject]');
        if (!subBtn) return;
        this.state.subject = subBtn.dataset.subject;
        this.navigate('home');
      });

      const wideSearch = () => document.getElementById('global-search');
      const debouncedRenderView = util.debounce(() => this.renderView(), 180);
      document.addEventListener('input', (e) => {
        if (e.target && e.target.id === 'global-search') {
          this.state.query = e.target.value;
          debouncedRenderView();
        }
      });

      document.addEventListener('keydown', (e) => {
        const mod = e.ctrlKey || e.metaKey;
        if (!mod) return;
        const k = e.key.toLowerCase();
        if (k === 'n') { e.preventDefault(); S.ui.modal.openImport(); }
        else if (k === 'f') {
          e.preventDefault();
          const el = wideSearch() || document.getElementById('home-search');
          if (el) el.focus();
        } else if (k === '1') { e.preventDefault(); this.navigate('home'); }
        else if (k === '2') { e.preventDefault(); this.navigate('notes'); }
        else if (k === '3') { e.preventDefault(); this.navigate('calendar'); }
        else if (k === '4') { e.preventDefault(); this.navigate('stats'); }
        else if (k === '5') { e.preventDefault(); this.navigate('settings'); }
      });

      window.addEventListener('beforeunload', () => store.persist && store.persist());
    },

    loadSample() {
      const confirmLoad = () => {
        const today = util.todayStr();
        const add = (p) => util.toISODate(util.addDays(util.parseDate(today), p));
        store.reset();
        store.addTasks([
          { subject: '数学', title: '试卷一张', subtitle: '写完对答案', priority: 1, dueDate: add(2), order: 1 },
          { subject: '数学', title: '默写平行四边形判定方法', subtitle: '写在一张纸上，周一收', priority: 2, dueDate: add(1), order: 2 },
          { subject: '语文', title: '背《昆虫记》讲义', subtitle: '自己印的', priority: 1, dueDate: add(3), order: 3 },
          { subject: '英语', title: '默写 49 个过去分词', subtitle: '优秀组默 1 遍', priority: 1, dueDate: today, order: 4 },
          { subject: '物理', title: '预习第三章', subtitle: '圈出不懂的地方', priority: 0, dueDate: add(4), order: 5 },
          { subject: '化学', title: '完成练习册 P12-15', priority: 1, dueDate: add(5), order: 6 },
          { subject: '语文', title: '抄古诗 3 遍', subtitle: '《望岳》', priority: 1, isCompleted: true, completedAt: new Date(Date.now() - 86400000 * 1).toISOString(), dueDate: add(-1) },
          { subject: '英语', title: '默写过去分词', isCompleted: true, completedAt: new Date(Date.now() - 86400000 * 2).toISOString(), dueDate: add(-2) },
          { subject: '数学', title: '口算练习 2 页', isCompleted: true, completedAt: new Date(Date.now() - 86400000 * 2).toISOString(), dueDate: add(-2) }
        ]);
        this.state.query = '';
        this.state.subject = '全部';
        this.state.priority = 'all';
      S.ui.toast('示例数据已载入');
      };
      if (store.state.tasks.some((t) => !t.isDeleted)) {
        S.ui.modal.confirm({
          title: '载入示例数据',
          message: '将清空当前任务并载入示例数据，确定吗？',
          confirmText: '载入',
          onConfirm: confirmLoad
        });
      } else {
        confirmLoad();
      }
    },

    celebrate() {
      S.ui.toast('太棒啦！全部完成！');
      const colors = [
        'var(--pink-strong)', 'var(--mint-strong)', 'var(--sky-strong)',
        'var(--lavender-strong)', 'var(--peach-strong)', 'var(--yellow-strong)'
      ];
      for (let i = 0; i < 90; i++) {
        const el = document.createElement('i');
        el.className = 'confetti-piece';
        const size = 6 + Math.random() * 8;
        el.style.cssText =
          'left:' + (Math.random() * 100) + 'vw;' +
          'width:' + size + 'px;height:' + (size * (0.6 + Math.random())) + 'px;' +
          'background:' + colors[i % colors.length] + ';' +
          'animation-duration:' + (1.4 + Math.random() * 1.6) + 's;' +
          'animation-delay:' + (Math.random() * 0.4) + 's;' +
          'border-radius:' + (Math.random() > 0.5 ? '50%' : '3px');
        document.body.appendChild(el);
        setTimeout(() => el.remove(), 3600);
      }
    }
  };

  function ringSvg(rate, gid) {
    const r = 40;
    const c = 2 * Math.PI * r;
    const offset = c * (1 - Math.min(rate, 100) / 100);
    return '<svg viewBox="0 0 100 100" style="width:74px;height:74px;flex:none">' +
      '<defs><linearGradient id="' + gid + '" x1="0" y1="0" x2="1" y2="1">' +
      '<stop offset="0" stop-color="var(--pink-strong)"/><stop offset="1" stop-color="var(--mint-strong)"/>' +
      '</linearGradient></defs>' +
      '<circle cx="50" cy="50" r="' + r + '" fill="none" stroke="var(--surface-3)" stroke-width="10"/>' +
      '<circle cx="50" cy="50" r="' + r + '" fill="none" stroke="url(#' + gid + ')" stroke-width="10" stroke-linecap="round" ' +
      'stroke-dasharray="' + c.toFixed(1) + '" stroke-dashoffset="' + offset.toFixed(1) + '" transform="rotate(-90 50 50)"/>' +
      '</svg>';
  }

  g.App = App;
  document.addEventListener('DOMContentLoaded', () => App.init());

  function transitionDir(from, to) {
    if (!from) return null; // 初始化 / 数据刷新：不加页面级方向动画
    const a = VIEW_ORDER.indexOf(from);
    const b = VIEW_ORDER.indexOf(to);
    if (a === b) return null;
    return b > a ? 'left' : 'right';
  }
})(typeof window !== 'undefined' ? window : globalThis);
