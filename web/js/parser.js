/* 糖纸 · SugarPaper —— 文本解析引擎
   粘贴老师消息 → 科目行 / 编号条目 / 子行 → 结构化任务列表
   纯正则实现，无外部依赖。 */
(function (g) {
  'use strict';

  const KNOWN_SUBJECTS = [
    // 小学/初中/高中统一默认学科（PRD v4.1）
    '语文', '数学', '英语', '物理', '化学', '生物', '历史', '地理', '政治',
    '体育与健康', '音乐', '美术', '信息技术', '通用技术', '劳动', '综合实践活动',
    // 常见别名与兜底
    '道法', '道德与法治', '体育', '信息', '综合实践', '科学',
    '默认', '未分类', '综合'
  ];

  // 编号条目：1. 1、 (1) ① - • 等
  const ITEM_RE = /^\s*(?:(\d{1,3})[.、．.)）]|([①-⑳])|[-•·*])\s*(.+?)\s*$/;
  // 作业动作词（用于启发式判断“这行不是科目行”）
  const TASK_WORDS = /题|卷|书|文|本|册|作业|抄|背|默|写|读|练|预习|复习|订正|检查|完成|背诵|听写|作文|古诗|讲义|试卷|练习|阅读|计算|画|做|准备|打印|下载|上传|提交|打卡/;
  // 行尾标点（句号/分号/冒号等 → 更像普通句子）
  const SENTENCE_END = /[。；：:，,！？!?]$/;

  const PRI_HIGH_WORDS = /高|重要|紧急|必须|必做|优先|重点/;
  const PRI_LOW_WORDS = /低|选做|可做可不做|有空再做|加分/;
  const DUE_TODAY = /今天|今日/;
  const DUE_TOMORROW = /明天|明日/;
  const DUE_DAY_AFTER = /后天/;

  function dateStr(d) {
    return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
  }

  function parseDateText(s) {
    const d = s.match(/(\d{1,2})月(\d{1,2})日/);
    if (d) return { m: +d[1], day: +d[2] };
    const d2 = s.match(/(\d{1,2})[./-](\d{1,2})(?!\d)/);
    if (d2 && +d2[1] <= 12) return { m: +d2[1], day: +d2[2] };
    return null;
  }

  function nextWeekdayDate(dayIndex) {
    const today = new Date();
    const cur = (today.getDay() + 6) % 7; // 周一=0
    let diff = dayIndex - cur;
    if (diff <= 0) diff += 7;
    const t = new Date(today.getFullYear(), today.getMonth(), today.getDate() + diff);
    return dateStr(t);
  }

  function extractDueDate(text) {
    const t = String(text || '');
    let base = null;
    if (DUE_TODAY.test(t)) base = new Date();
    else if (DUE_TOMORROW.test(t)) base = new Date(Date.now() + 86400000);
    else if (DUE_DAY_AFTER.test(t)) base = new Date(Date.now() + 2 * 86400000);
    else {
      const m = t.match(/(?:周|星期|礼拜)([一二三四五六日天])/);
      if (m) {
        const map = { '一': 0, '二': 1, '三': 2, '四': 3, '五': 4, '六': 5, '日': 6, '天': 6 };
        return nextWeekdayDate(map[m[1]]);
      }
      const md = parseDateText(t);
      if (md) {
        const now = new Date();
        let y = now.getFullYear();
        let cand = new Date(y, md.m - 1, md.day);
        if (cand.getTime() < now.getTime() - 86400000) {
          y += 1;
          cand = new Date(y, md.m - 1, md.day);
        }
        return dateStr(cand);
      }
    }
    if (base) {
      const b = new Date(base.getFullYear(), base.getMonth(), base.getDate());
      return dateStr(b);
    }
    return null;
  }

  function extractPriority(text) {
    const t = String(text || '');
    if (PRI_HIGH_WORDS.test(t)) return 2;
    if (PRI_LOW_WORDS.test(t)) return 0;
    return 1;
  }

  function cleanItemTitle(text) {
    return String(text || '').trim();
  }

  function isSubjectLine(line, subjectNames) {
    const t = line.trim();
    if (!t) return false;
    const names = new Set(subjectNames.concat(KNOWN_SUBJECTS));
    if (names.has(t)) return true;
    return isHeuristicSubject(t);
  }

  function isHeuristicSubject(t) {
    // 启发式：短小、纯中文、无作业动作词、不以句号结尾 → 可能是科目行
    return t.length <= 6 &&
      /^[\u4e00-\u9fa5A-Za-z0-9]+$/.test(t) &&
      !TASK_WORDS.test(t) &&
      !SENTENCE_END.test(t);
  }

  /**
   * 解析粘贴文本
   * @param {string} text 原始文本
   * @param {Array<{name:string}>} subjects 已配置科目（用于识别科目行）
   * @returns {Array<{subject:string,title:string,subtitle:string,priority:number,dueDate:string|null}>}
   */
  function parse(text, subjects) {
    const subjectNames = (subjects || []).map((s) => s.name);
    const rawLines = String(text || '').split(/\r?\n/).map((l) => l.trim());
    const lines = rawLines.filter((l) => l.length > 0);
    const result = [];
    let currentSubject = null;
    let sawAnySubject = false;
    let lastTask = null;

    // 第一遍：识别科目行（已知科目名，或“短行 + 紧随编号条目”的启发式）
    const names = new Set(subjectNames.concat(KNOWN_SUBJECTS));
    const itemMatch = lines.map((l) => l.match(ITEM_RE));
    const isHeader = lines.map((l) => {
      if (names.has(l)) return true;
      if (!isHeuristicSubject(l)) return false;
      return false; // 待第二遍结合下文判断
    });
    for (let i = 0; i < lines.length; i++) {
      if (isHeader[i] || !isHeuristicSubject(lines[i])) continue;
      // 启发式候选：其后 3 行内出现编号条目 → 视为科目行
      for (let j = i + 1; j <= Math.min(i + 3, lines.length - 1); j++) {
        if (itemMatch[j]) {
          isHeader[i] = true;
          break;
        }
      }
    }

    // 第二遍：正式解析
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      if (isHeader[i]) {
        currentSubject = line;
        sawAnySubject = true;
        lastTask = null;
        continue;
      }

      const m = itemMatch[i];
      if (m) {
        const title = cleanItemTitle(m[3]);
        if (!title) continue;
        const task = {
          subject: currentSubject || (sawAnySubject ? currentSubject : '默认'),
          title,
          subtitle: '',
          priority: extractPriority(title),
          dueDate: extractDueDate(title)
        };
        result.push(task);
        lastTask = task;
        continue;
      }

      // 非编号行 → 追加为上一个任务的子行（附加描述）
      if (lastTask) {
        const more = extractDueDate(line);
        if (more && !lastTask.dueDate) lastTask.dueDate = more;
        const pri = extractPriority(line);
        if (pri > lastTask.priority) lastTask.priority = pri;
        lastTask.subtitle = lastTask.subtitle
          ? lastTask.subtitle + '\n' + line
          : line;
      } else if (!sawAnySubject && result.length === 0) {
        // 无任何结构信息：整段视为一个任务（兜底）
        const task = {
          subject: '默认',
          title: line,
          subtitle: '',
          priority: extractPriority(line),
          dueDate: extractDueDate(line)
        };
        result.push(task);
        lastTask = task;
      }
    }

    // 去掉标题为空的任务；为无科目任务补“默认”
    return result.filter((t) => t.title).map((t) => ({
      ...t,
      subject: t.subject || '默认'
    }));
  }

  const api = { parse, extractDueDate, extractPriority, isSubjectLine };
  g.Sugar = g.Sugar || {};
  g.Sugar.parser = api;
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
})(typeof window !== 'undefined' ? window : globalThis);
