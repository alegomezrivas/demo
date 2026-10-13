import { randomUUID } from 'node:crypto';
import type { RequestHandler } from 'express';
import type { Logger } from '../logging/logger.js';

const REQUEST_ID_HEADER = 'X-Request-Id';

/** Assigns a request id and logs one line per finished request (path only, no query). */
export function requestContext(logger: Logger): RequestHandler {
  return (req, res, next) => {
    const requestId = randomUUID();
    res.locals['requestId'] = requestId;
    res.setHeader(REQUEST_ID_HEADER, requestId);
    const startedAt = process.hrtime.bigint();
    res.on('finish', () => {
      const durationMs = Number(process.hrtime.bigint() - startedAt) / 1e6;
      logger.info(
        { requestId, method: req.method, path: req.path, status: res.statusCode, durationMs },
        'request completed',
      );
    });
    next();
  };
}
