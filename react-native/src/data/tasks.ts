/** Task line: optional blockquote markers, `-`/`*` list marker, then `[ ]` or `[x]`. */
const TASK_RE = /^(\s*(?:>\s*)*[-*]\s+\[)([ xX])(\](?:\s|$))/;

type TaskLine = { line: number; checked: boolean };

function scanTasks(body: string): TaskLine[] {
  const out: TaskLine[] = [];
  let inFence = false;
  body.split('\n').forEach((l, i) => {
    if (l.trim().startsWith('```')) {
      inFence = !inFence;
      return;
    }
    if (inFence) return;
    const m = TASK_RE.exec(l);
    if (m) out.push({ line: i, checked: m[2] !== ' ' });
  });
  return out;
}

export function taskProgress(body: string): { done: number; total: number } {
  const tasks = scanTasks(body);
  return { done: tasks.filter((t) => t.checked).length, total: tasks.length };
}

/** Flips the `index`-th task (document order) between `[ ]` and `[x]`. */
export function toggleTask(body: string, index: number): string {
  const task = scanTasks(body)[index];
  if (!task) return body;
  const lines = body.split('\n');
  lines[task.line] = lines[task.line].replace(TASK_RE, (_m, a, c, b) => `${a}${c === ' ' ? 'x' : ' '}${b}`);
  return lines.join('\n');
}
