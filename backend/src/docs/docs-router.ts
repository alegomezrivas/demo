import { Router } from 'express';
import helmet from 'helmet';
import swaggerUi from 'swagger-ui-express';

/**
 * Serves the OpenAPI document (`/openapi.json`) and Swagger UI (`/docs`).
 *
 * Swagger UI needs inline scripts and styles, so only these routes get a relaxed
 * Content-Security-Policy; the rest of the API keeps helmet's strict default.
 */
export function docsRouter(document: Record<string, unknown>): Router {
  const router = Router();
  router.get('/openapi.json', (_req, res) => {
    res.json(document);
  });
  router.use(
    '/docs',
    helmet({
      contentSecurityPolicy: {
        directives: {
          defaultSrc: ["'self'"],
          scriptSrc: ["'self'", "'unsafe-inline'"],
          styleSrc: ["'self'", "'unsafe-inline'"],
          imgSrc: ["'self'", 'data:'],
        },
      },
    }),
    swaggerUi.serve,
    swaggerUi.setup(document, { customSiteTitle: 'Stark Showcase API' }),
  );
  return router;
}
