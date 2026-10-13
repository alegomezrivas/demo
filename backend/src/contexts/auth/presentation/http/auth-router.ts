import { Router } from 'express';
import { AuthController, type AuthUseCases } from './auth-controller.js';

/** Routes of the auth context, mounted at `/auth`. */
export function authRouter(useCases: AuthUseCases): Router {
  const controller = new AuthController(useCases);
  const router = Router();
  router.post('/login', controller.login);
  router.post('/register', controller.register);
  router.post('/refresh', controller.refresh);
  // Backend-only for now: the Flutter app does not call it yet.
  router.post('/logout', controller.logout);
  return router;
}
