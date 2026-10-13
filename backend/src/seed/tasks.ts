import { TASK_PRIORITIES, type Task } from '../contexts/tasks/domain/task.js';

const TITLES = [
  'Preparar la demo',
  'Revisar pull requests',
  'Escribir pruebas unitarias',
  'Actualizar dependencias',
  'Diseñar la pantalla de ajustes',
  'Configurar el pipeline',
  'Documentar la arquitectura',
  'Auditar la seguridad',
  'Optimizar el arranque',
  'Planificar el sprint',
];

const HOUR_MS = 3_600_000;
const DAY_MS = 24 * HOUR_MS;

/** Mirrors the data of the app's own mock so both backends feel the same. */
function buildDemoTasks(ownerId: string, now: Date, count: number, firstId: number): Task[] {
  return Array.from({ length: count }, (_unused, i) => {
    const cycle = Math.floor(i / TITLES.length);
    return {
      id: `task-${String(firstId + i)}`,
      ownerId,
      title: `${TITLES[i % TITLES.length] ?? ''}${cycle > 0 ? ` #${String(cycle + 1)}` : ''}`,
      description: i % 2 === 0 ? `Detalle de la tarea ${String(i + 1)}` : '',
      priority: TASK_PRIORITIES[i % TASK_PRIORITIES.length] ?? 'medium',
      isDone: i % 4 === 0,
      createdAt: new Date(now.getTime() - (count - i) * HOUR_MS),
      dueDate: i % 3 === 0 ? null : new Date(now.getTime() + ((i % 9) - 3) * DAY_MS),
    };
  });
}

/** Tasks of the seeded accounts: 23 for the demo user, 5 for the second one. */
export function buildSeedTasks(now: Date): Task[] {
  return [
    ...buildDemoTasks('user-0', now, 23, 0),
    ...buildDemoTasks('user-1', now, 5, 23).map((task) => ({
      ...task,
      title: `[Ana] ${task.title}`,
    })),
  ];
}
