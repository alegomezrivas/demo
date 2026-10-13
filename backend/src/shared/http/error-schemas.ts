import { z } from 'zod';

/** Uniform error body returned by every failing endpoint. */
export const errorBodySchema = z.strictObject({
  code: z.string().describe('Machine-readable identifier; the Flutter app only reads this field.'),
  message: z.string().describe('Generic human-readable text, never internal details.'),
  details: z
    .array(z.strictObject({ field: z.string(), issue: z.string() }))
    .optional()
    .describe('Field-level problems (validation errors only). Input values are never echoed.'),
});
