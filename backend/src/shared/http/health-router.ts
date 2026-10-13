import { Router } from 'express';

/** Liveness probe; exposes nothing about the environment. */
export function healthRouter(): Router {
  const router = Router();
  router.get('/health', (_req, res) => {
    res.status(200).json({ status: 'ok' });
  });
  return router;
}
