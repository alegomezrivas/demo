import type { RequestHandler } from 'express';
import type { CheckUsernameAvailability } from '../../application/check-username-availability.js';
import type { LoginUser } from '../../application/login-user.js';
import type { LogoutUser } from '../../application/logout-user.js';
import type { RefreshSession } from '../../application/refresh-session.js';
import type { AuthResult, RegisterUser } from '../../application/register-user.js';
import type { SendSignUpCode } from '../../application/send-signup-code.js';
import type { VerifySignUpCode } from '../../application/verify-signup-code.js';
import {
  loginRequestSchema,
  logoutRequestSchema,
  refreshRequestSchema,
  registerRequestSchema,
  signUpEmailRequestSchema,
  usernameQuerySchema,
  verifyCodeRequestSchema,
} from './auth-schemas.js';

export interface AuthUseCases {
  readonly register: RegisterUser;
  readonly login: LoginUser;
  readonly refresh: RefreshSession;
  readonly logout: LogoutUser;
  readonly sendCode: SendSignUpCode;
  readonly verifyCode: VerifySignUpCode;
  readonly checkUsername: CheckUsernameAvailability;
}

function toAuthResponse({ user, hasAvatar, accessToken, refreshToken }: AuthResult): object {
  // The password hash never leaves the domain.
  return {
    user: { id: user.id, name: user.name, email: user.email, username: user.username, hasAvatar },
    accessToken,
    refreshToken,
  };
}

/** Thin HTTP adapter: validate, delegate to a use case, shape the response. */
export class AuthController {
  constructor(private readonly useCases: AuthUseCases) {}

  readonly register: RequestHandler = async (req, res) => {
    const body = registerRequestSchema.parse(req.body);
    res.status(201).json(toAuthResponse(await this.useCases.register.execute(body)));
  };

  readonly sendCode: RequestHandler = async (req, res) => {
    const { email } = signUpEmailRequestSchema.parse(req.body);
    await this.useCases.sendCode.execute(email, { resend: false });
    res.status(204).end();
  };

  readonly resendCode: RequestHandler = async (req, res) => {
    const { email } = signUpEmailRequestSchema.parse(req.body);
    await this.useCases.sendCode.execute(email, { resend: true });
    res.status(204).end();
  };

  readonly verifyCode: RequestHandler = async (req, res) => {
    const { email, code } = verifyCodeRequestSchema.parse(req.body);
    const verificationToken = await this.useCases.verifyCode.execute(email, code);
    res.status(200).json({ verificationToken });
  };

  readonly usernameAvailable: RequestHandler = async (req, res) => {
    const { username } = usernameQuerySchema.parse(req.query);
    res.status(200).json({ available: await this.useCases.checkUsername.execute(username) });
  };

  readonly login: RequestHandler = async (req, res) => {
    const body = loginRequestSchema.parse(req.body);
    res.status(200).json(toAuthResponse(await this.useCases.login.execute(body)));
  };

  readonly refresh: RequestHandler = async (req, res) => {
    const { refreshToken } = refreshRequestSchema.parse(req.body);
    res.status(200).json(await this.useCases.refresh.execute(refreshToken));
  };

  readonly logout: RequestHandler = async (req, res) => {
    const { refreshToken } = logoutRequestSchema.parse(req.body);
    await this.useCases.logout.execute(refreshToken);
    res.status(204).end();
  };
}
