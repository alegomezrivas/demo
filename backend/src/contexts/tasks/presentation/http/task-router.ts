import { Router, type RequestHandler } from 'express';
import { TaskController, type TaskUseCases } from './task-controller.js';

/** Routes of the tasks context, mounted at `/tasks`; every one requires authentication. */
export function taskRouter(useCases: TaskUseCases, authenticate: RequestHandler): Router {
  const controller = new TaskController(useCases);
  const router = Router();
  router.use(authenticate);
  router.get('/', controller.list);
  // Must be declared before `/:id`, otherwise "stats" would be read as an id.
  router.get('/stats', controller.stats);
  router.post('/', controller.create);
  router.get('/:id', controller.get);
  router.put('/:id', controller.update);
  router.delete('/:id', controller.remove);
  return router;
}
