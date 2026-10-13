import type { DestinationStream } from 'pino';
import { pino, type Logger } from 'pino';

export type { Logger } from 'pino';

/** Paths whose values must never reach the logs. */
const REDACTED_PATHS = [
  'password',
  'code',
  'verificationToken',
  'refreshToken',
  'accessToken',
  '*.password',
  '*.code',
  '*.verificationToken',
  '*.refreshToken',
  '*.accessToken',
  'req.headers.authorization',
  'headers.authorization',
];

/** Creates the application logger with sensitive fields redacted. */
export function createLogger(level: string, destination?: DestinationStream): Logger {
  const options = { level, redact: { paths: REDACTED_PATHS, censor: '[redacted]' } };
  return destination === undefined ? pino(options) : pino(options, destination);
}
