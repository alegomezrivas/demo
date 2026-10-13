import type { RequestHandler } from 'express';
import type { LoginUser } from '../../application/login-user.js';
import type { LogoutUser } from '../../application/logout-user.js';
import type { RefreshSession } from '../../application/refresh-session.js';
import type { AuthResult, RegisterUser } from '../../application/register-user.js';
import {
  loginRequestSchema,
  logoutRequestSchema,
  refreshRequestSchema,
  registerRequestSchema,
} from './auth-schemas.js';

export interface AuthUseCases {
  readonly register: RegisterUser;
  readonly login: LoginUser;
  readonly refresh: RefreshSession;
  readonly logout: LogoutUser;
}

function toAuthResponse({ user, accessToken, refreshToken }: AuthResult): object {
  // The password hash never leaves the domain.
  return {
    user: { id: user.id, name: user.name, email: user.email, phone: user.phone },
    accessToken,
    refreshToken,
  };
}

/** Thin HTTP adapter: validate, delegate to a use case, shape the response. */
export class AuthController {
  constructor(private readonly useCases: AuthUseCases) {}

  readonly register: RequestHandler = async (req, res) => {
    const body = registerRequestSchema.parse(req.body);
    const result = await this.useCases.register.execute({ ...body, phone: body.phone ?? null });
    res.status(201).json(toAuthResponse(result));
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
