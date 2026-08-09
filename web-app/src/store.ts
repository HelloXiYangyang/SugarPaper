import { reactive } from 'vue';

export interface Task {
  id: string;
  title: string;
  subject: string;
  color: string;
  due: string;
  overdue?: boolean;
  done?: boolean;
  kind?: 'checkin' | 'recite' | 'written';
  priority?: number;
}

/** 与 contracts/tests/xp.json 一致：打卡 10 / 背诵 15 / 书面 20，高优先级 +50%，逾期双倍 */
export function xpOf(kind: Task['kind'], priority: number, overdue: boolean): number {
  const base = kind === 'checkin' ? 10 : kind === 'recite' ? 15 : 20;
  let xp = base;
  if (priority >= 3) xp = Math.round(xp * 1.5);
  if (overdue) xp *= 2;
  return xp;
}

export const store = reactive({
  dark: localStorage.getItem('sp:dark') === '1',
  tasks: [
    { id: '1', title: '试卷订正', subject: '数学', color: '#D9577A', due: '今天 18:00', kind: 'written', priority: 3 },
    { id: '2', title: '背诵第 3 课', subject: '语文', color: '#E05A5A', due: '今天', kind: 'recite', priority: 0 },
    { id: '3', title: '单词抄写', subject: '英语', color: '#E06A9A', due: '今天', kind: 'written', priority: 0 },
    { id: '4', title: '实验报告', subject: '物理', color: '#E88A3C', due: '2 天', overdue: true, kind: 'written', priority: 0 },
    { id: '5', title: '历史练习册', subject: '历史', color: '#5FA84F', due: '周五', kind: 'checkin', priority: 0 },
    { id: '6', title: '地理图册', subject: '地理', color: '#0FA47F', due: '周日', kind: 'checkin', priority: 0 }
  ] as Task[],
  toggleDark() {
    this.dark = !this.dark;
    localStorage.setItem('sp:dark', this.dark ? '1' : '0');
  },
  addTask(t: Task) {
    this.tasks.unshift(t);
  },
  toggleDone(id: string) {
    const t = this.tasks.find((x) => x.id === id);
    if (t) t.done = !t.done;
  }
});
