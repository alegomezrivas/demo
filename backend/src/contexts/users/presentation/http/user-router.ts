import express, { Router, type RequestHandler } from 'express';
import { AVATAR_MAX_BYTES } from '../../application/avatar-use-cases.js';
import { AvatarController, type UserUseCases } from './avatar-controller.js';

/** Routes of the users context, mounted at `/users`; every route needs a session. */
export function userRouter(useCases: UserUseCases, auth: RequestHandler): Router {
  const controller = new AvatarController(useCases);
  const router = Router();
  router.use(auth);
  router.get('/me/avatar', controller.get);
  // Any Content-Type is read as raw bytes; the use case validates the real format.
  router.put(
    '/me/avatar',
    express.raw({ type: () => true, limit: AVATAR_MAX_BYTES }),
    controller.put,
  );
  return router;
}
