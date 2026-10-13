import cors from 'cors';
import express, { type Express } from 'express';
import helmet from 'helmet';
import type { AppConfig } from './config/env.js';
import { errorHandler } from './shared/http/error-handler.js';
import { healthRouter } from './shared/http/health-router.js';
import { notFoundHandler } from './shared/http/not-found.js';
import { requestContext } from './shared/http/request-context.js';
import type { Logger } from './shared/logging/logger.js';

export interface AppDependencies {
  readonly config: AppConfig;
  readonly logger: Logger;
}

/** Builds the Express app without listening, so tests can drive it with supertest. */
export function createApp({ config, logger }: AppDependencies): Express {
  const app = express();
  app.set('trust proxy', config.trustProxy ? 1 : false);

  app.use(requestContext(logger));
  app.use(helmet());
  // Native apps do not need CORS; only the listed origins (if any) are allowed.
  app.use(
    cors({ origin: config.corsAllowedOrigins.length > 0 ? [...config.corsAllowedOrigins] : false }),
  );
  app.use(express.json({ limit: config.bodyLimit }));

  app.use(healthRouter());

  app.use(notFoundHandler);
  app.use(errorHandler(logger));
  return app;
}
