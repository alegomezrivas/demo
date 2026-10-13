import { Router } from 'express';

/**
 * `POST /__reset`: restores the seed data. Only mounted outside production
 * (see `AppConfig.resetEndpointEnabled`); in production the route does not exist.
 */
export function resetRouter(reset: () => Promise<void>): Router {
  const router = Router();
  router.post('/__reset', async (_req, res) => {
    await reset();
    res.status(204).end();
  });
  return router;
}
