/*
 * Copyright (C) 2026 HelloXiYangyang
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

/* 糖纸 · SugarPaper —— 弹窗 / 对话框 / Toast */
(function (g) {
  'use strict';

  const S = g.Sugar;
  const util = S.util;
  const store = S.store;

  const modalRoot = () => document.getElementById('modal-root');
  const toastRoot = () => document.getElementById('toast-root');

  function closeAll() {
    const root = modalRoot();
    if (root) root.innerHTML = '';
  }

  function open({ title, body, footer, wide }) {
    closeAll();
    const mask = document.createElement('div');
    mask.className = 'modal-mask';
    const modal = document.createElement('div');
    modal.className = 'modal' + (wide ? ' wide' : '');
    modal.innerHTML =
      '<div class="modal-head"><h2>' + util.escapeHtml(title) + '</h2>' +
      '<button class="icon-btn" data-action="close">' + S.icons.icon('close', 16) + '</button></div>' +
      '<div class="modal-body"></div>' +
      (footer != null ? '<div class="modal-foot"></div>' : '');
    const bodyEl = modal.querySelector('.modal-body');
    const footEl = modal.querySelector('.modal-foot');
    if (typeof body === 'string') bodyEl.innerHTML = body;
    else if (body) bodyEl.appendChild(body);
    if (footer != null) {
      if (typeof footer === 'string') footEl.innerHTML = footer;
      else if (footer) footEl.appendChild(footer);
    }
    mask.appendChild(modal);
    modalRoot().appendChild(mask);

    mask.addEventListener('mousedown', (e) => {
      if (e.target === mask) closeAll();
    });
    modal.addEventListener('click', (e) => {
      const btn = e.target.closest('[data-action]');
      if (!btn) return;
      if (btn.dataset.action === 'close') closeAll();
    });

    const first = modal.querySelector('input, textarea, select');
    if (first) setTimeout(() => first.focus(), 30);
    return { mask, modal, bodyEl, footEl, close: closeAll };
  }

  function toast(msg, ms) {
    const root = toastRoot();
    if (!root) return;
    const el = document.createElement('div');
    el.className = 'toast';
    el.textContent = msg;
    root.appendChild(el);
    setTimeout(() => {
      el.classList.add('out');
      setTimeout(() => el.remove(), 260);
    }, ms || 2400);
  }

  function confirm({ title, message, confirmText, danger, onConfirm }) {
    const dlg = open({
      title: title || '确认操作',
      body: '<div style="font-size:14px;line-height:1.7;color:var(--text-2)">' + util.escapeHtml(message || '') + '</div>',
      footer: ''
    });
    dlg.footEl.innerHTML =
      '<button class="btn" data-action="cancel">取消</button>' +
      '<button class="btn ' + (danger ? 'soft-danger' : 'primary') + '" data-action="ok">' +
      util.escapeHtml(confirmText || '确定') + '</button>';
    dlg.footEl.addEventListener('click', (e) => {
      const btn = e.target.closest('[data-action]');
      if (!btn) return;
      if (btn.dataset.action === 'cancel') dlg.close();
      else {
        dlg.close();
        if (onConfirm) onConfirm();
      }
    });
  }

  function prompt({ title, label, value, placeholder, onConfirm }) {
    const dlg = open({
      title,
      body:
        '<div class="field"><label>' + util.escapeHtml(label || '') + '</label>' +
        '<input type="text" id="prompt-input" value="' + util.escapeHtml(value || '') + '" placeholder="' + util.escapeHtml(placeholder || '') + '"></div>',
      footer: ''
    });
    dlg.footEl.innerHTML =
      '<button class="btn" data-action="cancel">取消</button>' +
      '<button class="btn primary" data-action="ok">确定</button>';
    dlg.footEl.addEventListener('click', (e) => {
      const btn = e.target.closest('[data-action]');
      if (!btn) return;
      const v = dlg.bodyEl.querySelector('#prompt-input').value.trim();
      if (btn.dataset.action === 'cancel') dlg.close();
      else {
        if (!v) { toast('内容不能为空'); return; }
        dlg.close();
        if (onConfirm) onConfirm(v);
      }
    });
    dlg.bodyEl.querySelector('#prompt-input').addEventListener('keydown', (e) => {
      if (e.key === 'Enter') dlg.footEl.querySelector('[data-action="ok"]').click();
    });
    return dlg;
  }

  /* ---------- 文本导入弹窗 ---------- */
  function openImport() {
    const dlg = open({
      title: '粘贴作业清单',
      footer: '',
      wide: true
    });
    dlg.bodyEl.innerHTML =
      '<div class="field"><textarea id="import-text" placeholder="示例：&#10;数学&#10;1.试卷一张&#10;2.默写平行四边形判定方法&#10;写在一张纸上 周一收&#10;语文&#10;1.背《昆虫记》讲义&#10;2.抄古诗3遍"></textarea></div>' +
      '<div style="display:flex;gap:8px;margin-bottom:12px">' +
      '<button class="btn soft-pink small" data-action="preview">' + S.icons.icon('eye', 13) + ' 预览解析</button>' +
      '<button class="btn small" data-action="sample">' + S.icons.icon('sparkles', 13) + ' 填入示例</button>' +
      '<button class="btn small" data-voice data-target="import-text" title="语音速记（浏览器支持时）">' + S.icons.icon('mic', 13) + ' 语音输入</button>' +
      '</div>' +
      '<div id="import-preview"></div>';
    dlg.footEl.innerHTML =
      '<button class="btn" data-action="cancel">' + S.icons.icon('close', 13) + ' 取消</button>' +
      '<button class="btn soft-pink" data-action="append">' + S.icons.icon('paperclip', 13) + ' 追加到末尾</button>' +
      '<button class="btn primary" data-action="overwrite">' + S.icons.icon('download', 13) + ' 导入并覆盖</button>';

    const previewEl = () => dlg.bodyEl.querySelector('#import-preview');
    const textEl = () => dlg.bodyEl.querySelector('#import-text');

    function renderPreview() {
      const text = textEl().value;
      if (!text.trim()) {
        previewEl().innerHTML = '<div class="empty"><div class="big">' + S.icons.icon('list', 40) + '</div>粘贴后点击“预览解析”，自动识别科目与编号条目。</div>';
        return [];
      }
      const detail = S.parser.parseDetailed(text, store.state.subjects);
      const tasks = detail.tasks;
      if (!tasks.length) {
        previewEl().innerHTML = '<div class="empty"><div class="big">' + S.icons.icon('help', 40) + '</div>没有解析到任务，请检查文本格式。</div>';
        return [];
      }
      const items = tasks.map((t, i) => {
        const color = store.getSubjectColor(t.subject);
        return '<div class="p-item" style="--i:' + i + '"><span class="p-sub" style="background:' + color + '">' +
          util.escapeHtml(t.subject) + '</span><span class="p-title">' + util.escapeHtml(t.title) +
          (t.dueDate ? ' <span style="color:var(--peach-strong);display:inline-flex;align-items:center;gap:2px;font-size:11px">' + S.icons.icon('calendar', 11) + util.fmtDate(t.dueDate) + '</span>' : '') +
          '</span></div>';
      }).join('');
      const warnings = detail.warnings.length
        ? '<div class="parse-warning">' + S.icons.icon('help', 12) + ' ' + util.escapeHtml(detail.warnings.join('；')) + '</div>'
        : '';
      previewEl().innerHTML =
        warnings +
        '<div class="field"><label>' + S.icons.icon('list', 12) + ' 预览结果（' + tasks.length + ' 项）</label></div>' +
        '<div class="preview-list">' + items + '</div>';
      return tasks;
    }

    dlg.bodyEl.querySelector('[data-action="sample"]').addEventListener('click', () => {
      textEl().value =
        '数学\n1.试卷一张\n2.默写平行四边形判定方法\n写在一张纸上 周一收\n' +
        '语文\n1.周六14:00考期末检测卷\n对答案 周一检查\n2.背《昆虫记》讲义\n自己印的\n' +
        '英语\n1.默写49个过去分词\n优秀组默1遍';
      renderPreview();
    });
    dlg.bodyEl.querySelector('[data-action="preview"]').addEventListener('click', renderPreview);
    initVoiceInput(dlg.bodyEl);
    dlg.footEl.addEventListener('click', (e) => {
      const btn = e.target.closest('[data-action]');
      if (!btn) return;
      if (btn.dataset.action === 'cancel') { dlg.close(); return; }
      const tasks = renderPreview();
      if (!tasks.length) { toast('没有可导入的任务'); return; }
      if (btn.dataset.action === 'overwrite') {
        store.importTasks(tasks, 'overwrite');
        toast('已覆盖导入 ' + tasks.length + ' 项作业');
      } else if (btn.dataset.action === 'append') {
        store.importTasks(tasks, 'append');
        toast('已追加 ' + tasks.length + ' 项作业');
      }
      dlg.close();
      g.App && g.App.render();
    });
    renderPreview();
  }

  /* ---------- 新建 / 编辑任务弹窗 ---------- */
  function openEdit(taskId, defaults) {
    const existing = taskId ? store.state.tasks.find((t) => t.id === taskId) : null;
    defaults = defaults || {};
    const subjects = store.state.subjects;
    const subjectOptions = subjects
      .filter((s) => s.enabled || (existing && existing.subject === s.name))
      .map((s) => '<option value="' + util.escapeHtml(s.name) + '">' + util.escapeHtml(s.name) + '</option>')
      .join('');
    const hasOption = subjectOptions.indexOf('value="' + (existing ? util.escapeHtml(existing.subject) : '') + '"') >= 0;
    const subjectOptionsFinal = hasOption || !existing
      ? subjectOptions
      : subjectOptions + '<option value="' + util.escapeHtml(existing.subject) + '">' + util.escapeHtml(existing.subject) + '</option>';

    const dlg = open({
      title: existing ? '编辑作业' : '新建作业',
      footer: ''
    });
    dlg.bodyEl.innerHTML =
      '<div class="field-row">' +
      '<div class="field"><label>科目</label><select id="edit-subject">' + subjectOptionsFinal + '</select></div>' +
      '<div class="field"><label>优先级</label><div class="prio-picker">' +
      '<button type="button" data-prio="0">低</button><button type="button" data-prio="1">中</button><button type="button" data-prio="2">高</button>' +
      '</div></div>' +
      '</div>' +
      '<div class="field"><label>作业内容</label><input type="text" id="edit-title" placeholder="例如：试卷一张"></div>' +
      '<div class="field"><label>附加描述（可选）</label><input type="text" id="edit-subtitle" placeholder="例如：写在一张纸上，周一收"></div>' +
      '<div class="field-row">' +
      '<div class="field"><label>截止日期</label><input type="date" id="edit-due"></div>' +
      (existing ? '<div class="field" style="display:flex;align-items:flex-end;padding-bottom:8px"><label style="display:flex;align-items:center;gap:8px;cursor:pointer"><input type="checkbox" id="edit-done" style="width:16px;height:16px"> 已完成</label></div>' : '') +
      '</div>';

    let prio = existing ? existing.priority : 1;
    function setPrio(p) {
      prio = p;
      dlg.bodyEl.querySelectorAll('.prio-picker button').forEach((b) => {
        b.classList.toggle('active', +b.dataset.prio === p);
      });
    }
    setPrio(prio);

    if (existing) {
      dlg.bodyEl.querySelector('#edit-title').value = existing.title;
      dlg.bodyEl.querySelector('#edit-subtitle').value = existing.subtitle || '';
      dlg.bodyEl.querySelector('#edit-subject').value = existing.subject;
      if (existing.dueDate) dlg.bodyEl.querySelector('#edit-due').value = existing.dueDate;
      dlg.bodyEl.querySelector('#edit-done').checked = existing.isCompleted;
    } else if (defaults.dueDate) {
      dlg.bodyEl.querySelector('#edit-due').value = defaults.dueDate;
    }
    if (defaults.subject) {
      try { dlg.bodyEl.querySelector('#edit-subject').value = defaults.subject; } catch (e) { /* 忽略 */ }
    }

    dlg.footEl.innerHTML =
      (existing ? '<button class="btn soft-pink" data-action="to-note">' + S.icons.icon('file-text', 13) + ' 转为便签</button>' : '') +
      '<button class="btn" data-action="cancel">取消</button>' +
      '<button class="btn primary" data-action="save">' + S.icons.icon('save', 13) + ' 保存</button>';

    dlg.bodyEl.querySelectorAll('.prio-picker button').forEach((b) => {
      b.addEventListener('click', () => setPrio(+b.dataset.prio));
    });
    dlg.footEl.addEventListener('click', (e) => {
      const btn = e.target.closest('[data-action]');
      if (!btn) return;
      if (btn.dataset.action === 'cancel') { dlg.close(); return; }
      if (btn.dataset.action === 'to-note') {
        store.addNote({
          title: existing.title,
          content: existing.subtitle || '',
          tags: ['作业备忘'],
          color: store.getSubjectColor(existing.subject)
        });
        toast('已转为便签（作业保留）');
        dlg.close();
        return;
      }
      const title = dlg.bodyEl.querySelector('#edit-title').value.trim();
      if (!title) { toast('作业内容不能为空'); return; }
      const patch = {
        subject: dlg.bodyEl.querySelector('#edit-subject').value,
        title,
        subtitle: dlg.bodyEl.querySelector('#edit-subtitle').value.trim(),
        priority: prio,
        dueDate: dlg.bodyEl.querySelector('#edit-due').value || null
      };
      if (existing) {
        const done = dlg.bodyEl.querySelector('#edit-done').checked;
        if (done !== existing.isCompleted) {
          store.toggleComplete(existing.id);
          store.updateTask(existing.id, patch);
        } else {
          store.updateTask(existing.id, patch);
        }
        toast('已保存');
      } else {
        store.addTask(patch);
        toast('已添加作业');
      }
      dlg.close();
      g.App && g.App.render();
    });
  }

  /* ---------- 便签编辑器（v0.15.0） ---------- */
  const NOTE_TEMPLATES = {
    '考试安排': '【考试安排】\n科目：\n时间：\n地点：\n需要携带：',
    '老师通知': '【老师通知】\n明天需要……',
    '物品清单': '【物品清单】\n□ \n□ \n□ ',
    '回执': '【家长签字回执】\n请家长签名：________'
  };

  function openNoteEditor(noteId) {
    const existing = noteId ? store.state.notes.find((n) => n.id === noteId) : null;
    const colors = S.ui.notes ? S.ui.notes.NOTE_COLORS : ['#F4B8CE', '#FBE6B9', '#BFE8C9', '#B3D4F0', '#C9C7F0', '#E8D5F0', '#FAD1B8', '#F0C9C9'];
    const swatches = colors.map((c) =>
      '<button type="button" class="swatch" data-color="' + c + '" style="background:' + c + '"></button>').join('');
    const dlg = open({
      title: existing ? '编辑便签' : '新建便签',
      footer: ''
    });
    dlg.bodyEl.innerHTML =
      '<div class="field"><label>标题（选填）</label><input type="text" id="note-title" placeholder="例如：6月28日数学期末考" value="' +
      util.escapeHtml(existing ? existing.title : '') + '"></div>' +
      '<div class="field"><label>内容</label><textarea id="note-content" placeholder="随手记下考试安排、老师通知、明天带什么……">' +
      util.escapeHtml(existing ? existing.content : '') + '</textarea></div>' +
      '<div class="field"><label>颜色</label><div class="swatch-row">' + swatches + '</div></div>' +
      '<div class="field-row">' +
      '<div class="field"><label>标签</label><select id="note-tag">' +
      '<option value="">无标签</option>' +
      (S.ui.notes ? S.ui.notes.NOTE_TAGS.map((t) =>
        '<option value="' + util.escapeHtml(t) + '"' + (existing && existing.tags && existing.tags.includes(t) ? ' selected' : '') + '>' + util.escapeHtml(t) + '</option>').join('') : '') +
      '</select></div>' +
      '<div class="field"><label>提醒时间（可选）</label><input type="datetime-local" id="note-remind" value="' +
      (existing && existing.remindAt ? toLocalInput(existing.remindAt) : '') + '"></div>' +
      '</div>' +
      '<div class="field"><label style="display:flex;align-items:center;gap:8px;cursor:pointer">' +
      '<input type="checkbox" id="note-pinned" style="width:16px;height:16px"' + (existing && existing.pinned ? ' checked' : '') + '> 置顶</label></div>' +
      '<div class="field"><label>模板</label><div style="display:flex;gap:8px;flex-wrap:wrap">' +
      Object.keys(NOTE_TEMPLATES).map((t) =>
        '<button type="button" class="btn small" data-template="' + util.escapeHtml(t) + '">' + util.escapeHtml(t) + '</button>').join('') +
      '</div></div>' +
      '<div class="field"><label>语音速记</label><button type="button" class="btn small soft-pink" data-voice data-target="note-content">' +
      S.icons.icon('mic', 13) + ' 语音输入（说作业、说通知）</button>' +
      '<div style="font-size:12px;color:var(--text-3);margin-top:6px">识别结果自动填入内容框，可一键转成作业。</div></div>';
    dlg.footEl.innerHTML =
      (existing ? '<button class="btn soft-pink" data-action="to-task">' + S.icons.icon('list', 13) + ' 转为作业</button>' : '') +
      '<button class="btn" data-action="cancel">取消</button>' +
      '<button class="btn primary" data-action="save">' + S.icons.icon('save', 13) + ' 保存</button>';

    let color = existing ? existing.color : colors[0];
    dlg.bodyEl.querySelectorAll('.swatch').forEach((s) => {
      if (s.dataset.color === color) s.classList.add('active');
      s.addEventListener('click', () => {
        color = s.dataset.color;
        dlg.bodyEl.querySelectorAll('.swatch').forEach((x) => x.classList.remove('active'));
        s.classList.add('active');
      });
    });
    dlg.bodyEl.querySelectorAll('[data-template]').forEach((b) => {
      b.addEventListener('click', () => {
        dlg.bodyEl.querySelector('#note-content').value = NOTE_TEMPLATES[b.dataset.template];
        dlg.bodyEl.querySelector('#note-title').focus();
      });
    });
    initVoiceInput(dlg.bodyEl);
    dlg.footEl.addEventListener('click', (e) => {
      const btn = e.target.closest('[data-action]');
      if (!btn) return;
      if (btn.dataset.action === 'cancel') { dlg.close(); return; }
      if (btn.dataset.action === 'to-task' && existing) {
        noteToTask(existing.id);
        dlg.close();
        return;
      }
      const title = dlg.bodyEl.querySelector('#note-title').value.trim();
      const content = dlg.bodyEl.querySelector('#note-content').value.trim();
      if (!title && !content) { toast('便签内容不能为空'); return; }
      const tag = dlg.bodyEl.querySelector('#note-tag').value;
      const remindVal = dlg.bodyEl.querySelector('#note-remind').value;
      const patch = {
        title,
        content,
        color,
        pinned: dlg.bodyEl.querySelector('#note-pinned').checked,
        tags: tag ? [tag] : [],
        remindAt: remindVal ? new Date(remindVal).toISOString() : null
      };
      if (existing) {
        store.updateNote(existing.id, patch);
        toast('便签已保存');
      } else {
        store.addNote(patch);
        toast('便签已添加');
      }
      dlg.close();
      g.App && g.App.render();
    });
  }

  function toLocalInput(iso) {
    const d = new Date(iso);
    if (isNaN(d.getTime())) return '';
    return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0') +
      'T' + String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0');
  }

  /** 语音速记（v0.18.0）：Web Speech API（zh-CN），浏览器不支持时隐藏按钮 */
  function initVoiceInput(root) {
    root.querySelectorAll('[data-voice]').forEach((btn) => {
      const SR = g.SpeechRecognition || g.webkitSpeechRecognition;
      if (!SR) {
        btn.hidden = true;
        return;
      }
      const target = root.querySelector('#' + btn.dataset.target);
      if (!target) return;
      let rec = null;
      const label = btn.innerHTML;
      btn.addEventListener('click', () => {
        if (rec) {
          try { rec.stop(); } catch (e) { /* 忽略 */ }
          return;
        }
        try {
          rec = new SR();
          rec.lang = 'zh-CN';
          rec.interimResults = true;
          rec.continuous = false;
          let finalText = '';
          rec.onresult = (e) => {
            let interim = '';
            for (let i = e.resultIndex; i < e.results.length; i++) {
              const t = e.results[i][0].transcript;
              if (e.results[i].isFinal) finalText += t;
              else interim += t;
            }
            target.value = target.value + finalText + interim;
          };
          const done = () => {
            rec = null;
            btn.classList.remove('recording');
            btn.innerHTML = label;
          };
          rec.onend = done;
          rec.onerror = () => { done(); toast('语音识别失败，请重试'); };
          rec.start();
          btn.classList.add('recording');
          btn.innerHTML = S.icons.icon('mic', 13) + ' 停止';
        } catch (err) {
          toast('无法启动语音识别');
        }
      });
    });
  }

  /** 便签 → 作业：优先复用解析引擎；解析不到时降级为单条任务 */
  function noteToTask(noteId) {
    const n = store.state.notes.find((x) => x.id === noteId);
    if (!n) return;
    const text = ((n.title || '') + '\n' + (n.content || '')).trim();
    const tasks = S.parser.parse(text, store.state.subjects);
    if (tasks.length) {
      const items = tasks.map((t, i) => {
        const color = store.getSubjectColor(t.subject);
        return '<div class="p-item" style="--i:' + i + '"><span class="p-sub" style="background:' + color + '">' +
          util.escapeHtml(t.subject) + '</span><span class="p-title">' + util.escapeHtml(t.title) + '</span></div>';
      }).join('');
      const dlg = open({
        title: '便签转为作业',
        body:
          '<div style="font-size:13px;color:var(--text-2);margin-bottom:10px">解析到 <b>' + tasks.length + '</b> 项作业，将追加到作业清单：</div>' +
          '<div class="preview-list">' + items + '</div>',
        footer: ''
      });
      dlg.footEl.innerHTML =
        '<button class="btn" data-action="cancel">取消</button>' +
        '<button class="btn primary" data-action="ok">' + S.icons.icon('list', 13) + ' 追加为作业</button>';
      dlg.footEl.addEventListener('click', (e) => {
        const btn = e.target.closest('[data-action]');
        if (!btn) return;
        if (btn.dataset.action === 'cancel') { dlg.close(); return; }
        store.importTasks(tasks, 'append');
        toast('已追加 ' + tasks.length + ' 项作业');
        dlg.close();
        g.App && g.App.render();
      });
      return;
    }
    const title = n.title || ((n.content || '').split('\n')[0] || '便签').slice(0, 30);
    store.addTask({ subject: '默认', title, subtitle: n.content || '' });
    toast('已转为作业');
    g.App && g.App.render();
  }

  g.Sugar = g.Sugar || {};
  g.Sugar.ui = g.Sugar.ui || {};
  g.Sugar.ui.modal = { open, closeAll, confirm, prompt, openImport, openEdit, openNoteEditor, noteToTask };
  g.Sugar.ui.toast = toast;
})(typeof window !== 'undefined' ? window : globalThis);
