import { Router } from 'express';
import { AuthController, type AuthUseCases } from './auth-controller.js';

/** Routes of the auth context, mounted at `/auth`. */
export function authRouter(useCases: AuthUseCases): Router {
  const controller = new AuthController(useCases);
  const router = Router();
  router.post('/login', controller.login);
  // Sign-up: confirm the e-mail first, then create the account with the proof.
  router.post('/signup/email', controller.sendCode);
  router.post('/signup/code/resend', controller.resendCode);
  router.post('/signup/verify', controller.verifyCode);
  router.get('/username-available', controller.usernameAvailable);
  router.post('/register', controller.register);
  router.post('/refresh', controller.refresh);
  // The Flutter app calls it on sign-out (best effort, with the refresh token).
  router.post('/logout', controller.logout);
  return router;
}
