/**
 * Checklist tasks (iteration 3): lines `- [ ] text` / `- [x] text` (also `*`).
 * Tasks are indexed in document order; lines inside code fences are ignored.
 */

const TASK_RE = /^(\s*[-*]\s+\[)([ xX])(\]\s)/;

export interface TaskInfo {
  line: number;
  checked: boolean;
}

export function noteTasks(body: string): TaskInfo[] {
  const out: TaskInfo[] = [];
  let inFence = false;
  body.split('\n').forEach((line, i) => {
    if (line.trim().startsWith('```')) {
      inFence = !inFence;
      return;
    }
    if (inFence) return;
    const m = TASK_RE.exec(line + ' ');
    if (m) out.push({ line: i, checked: m[2] !== ' ' });
  });
  return out;
}

/** `<done>/<total>` counts, or null when the note has no tasks. */
export function taskProgress(body: string): { done: number; total: number } | null {
  const tasks = noteTasks(body);
  if (tasks.length === 0) return null;
  return { done: tasks.filter((t) => t.checked).length, total: tasks.length };
}

/** Returns the body with task `index` toggled (`[ ]` <-> `[x]`). */
export function toggleTask(body: string, index: number): string {
  const task = noteTasks(body)[index];
  if (!task) return body;
  const lines = body.split('\n');
  const line = lines[task.line]!;
  lines[task.line] = (line + ' ')
    .replace(TASK_RE, (_all, a: string, _mark: string, b: string) => `${a}${task.checked ? ' ' : 'x'}${b}`)
    .slice(0, line.length);
  return lines.join('\n');
}
