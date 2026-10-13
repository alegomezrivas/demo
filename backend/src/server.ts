import { createApp } from './app.js';
import { ConfigError, loadConfig, type AppConfig } from './config/env.js';
import { createLogger } from './shared/logging/logger.js';

function readConfig(): AppConfig {
  try {
    return loadConfig();
  } catch (error) {
    if (error instanceof ConfigError) {
      console.error(error.message);
      process.exit(1);
    }
    throw error;
  }
}

function main(): void {
  const config = readConfig();
  const logger = createLogger(config.logLevel);
  const server = createApp({ config, logger }).listen(config.port, () => {
    logger.info({ port: config.port, env: config.env }, 'server listening');
  });

  const shutdown = (signal: string): void => {
    logger.info({ signal }, 'shutting down');
    server.close(() => {
      process.exit(0);
    });
  };
  process.on('SIGTERM', () => {
    shutdown('SIGTERM');
  });
  process.on('SIGINT', () => {
    shutdown('SIGINT');
  });
}

main();
