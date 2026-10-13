import cors from 'cors';
import express, { type Express, type RequestHandler } from 'express';
import helmet from 'helmet';
import type { Container } from './composition.js';
import type { AppConfig } from './config/env.js';
import { authRouter } from './contexts/auth/presentation/http/auth-router.js';
import { authenticate } from './contexts/auth/presentation/http/authenticate.js';
import { userRouter } from './contexts/users/presentation/http/user-router.js';
import { taskRouter } from './contexts/tasks/presentation/http/task-router.js';
import { docsRouter } from './docs/docs-router.js';
import { buildOpenApiDocument } from './docs/openapi.js';
import { errorHandler } from './shared/http/error-handler.js';
import { healthRouter } from './shared/http/health-router.js';
import { mockSimulation } from './shared/http/mock-simulation.js';
import { notFoundHandler } from './shared/http/not-found.js';
import { createRateLimiters } from './shared/http/rate-limit.js';
import { requestContext } from './shared/http/request-context.js';
import { resetRouter } from './shared/http/reset-router.js';
import type { Logger } from './shared/logging/logger.js';

export interface AppDependencies {
  readonly config: AppConfig;
  readonly logger: Logger;
  readonly container: Container;
  /** Tuning knobs for the dev/staging simulation (tests shorten the timeout hold). */
  readonly simulation?: { readonly timeoutHoldMs?: number };
}

/** Tokens must never be cached by browsers, proxies or intermediaries. */
const noStore: RequestHandler = (_req, res, next) => {
  res.setHeader('Cache-Control', 'no-store');
  next();
};

/** Builds the Express app without listening, so tests can drive it with supertest. */
export function createApp({ config, logger, container, simulation }: AppDependencies): Express {
  const app = express();
  app.set('trust proxy', config.trustProxy ? 1 : false);

  app.use(requestContext(logger));
  app.use(helmet());
  // Native apps do not need CORS; only the listed origins (if any) are allowed.
  app.use(
    cors({ origin: config.corsAllowedOrigins.length > 0 ? [...config.corsAllowedOrigins] : false }),
  );
  app.use(express.json({ limit: config.bodyLimit }));

  // Probes and documentation are exempt from rate limiting and from simulation.
  app.use(healthRouter());
  app.use(docsRouter(buildOpenApiDocument(config)));

  const limiters = createRateLimiters(config);
  app.use(limiters.general);
  app.use(['/auth/login', '/auth/register', '/auth/signup'], limiters.credentials);
  app.use('/auth/refresh', limiters.refresh);

  if (config.mockSimulationEnabled) {
    app.use(
      ['/auth', '/tasks', '/users'],
      mockSimulation({
        accessTokens: container.accessTokens,
        ...(simulation?.timeoutHoldMs === undefined
          ? {}
          : { timeoutHoldMs: simulation.timeoutHoldMs }),
      }),
    );
  }

  app.use('/auth', noStore, authRouter(container.auth));
  const requireSession = authenticate(container.authenticate);
  app.use('/tasks', taskRouter(container.tasks, requireSession));
  app.use('/users', noStore, userRouter(container.users, requireSession));
  if (config.resetEndpointEnabled) app.use(resetRouter(() => container.reset()));

  app.use(notFoundHandler);
  app.use(errorHandler(logger));
  return app;
}
