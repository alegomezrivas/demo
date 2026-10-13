import { z } from 'zod';

/** Password policy, defined once: mirrors the Flutter sign-up form. */
export const PASSWORD_MIN_LENGTH = 8;
export const PASSWORD_MAX_LENGTH = 128;

export const passwordPolicySchema = z
  .string()
  .min(PASSWORD_MIN_LENGTH)
  .max(PASSWORD_MAX_LENGTH)
  .refine((value) => /[A-Z]/.test(value), { message: 'missing_uppercase' })
  .refine((value) => /[a-z]/.test(value), { message: 'missing_lowercase' })
  .refine((value) => /[0-9]/.test(value), { message: 'missing_digit' })
  .refine((value) => /[^A-Za-z0-9]/.test(value), { message: 'missing_symbol' });

const emailSchema = z.string().trim().toLowerCase().pipe(z.email().max(254));

/** 7-15 digits with an optional leading plus, as sent by the app. */
const phoneSchema = z.string().regex(/^\+?[0-9]{7,15}$/);

// ---- Requests (strict: unknown keys are rejected) ----

export const loginRequestSchema = z.strictObject({
  email: emailSchema,
  // The policy is not enforced on login so existing accounts are never locked out.
  password: z.string().min(1).max(PASSWORD_MAX_LENGTH),
});

export const registerRequestSchema = z.strictObject({
  name: z.string().trim().min(1).max(100),
  email: emailSchema,
  password: passwordPolicySchema,
  phone: phoneSchema.nullish(),
});

const refreshTokenSchema = z.string().min(1).max(512);

export const refreshRequestSchema = z.strictObject({ refreshToken: refreshTokenSchema });
export const logoutRequestSchema = z.strictObject({ refreshToken: refreshTokenSchema });

// ---- Responses (also used by the contract tests and the OpenAPI document) ----

export const userResponseSchema = z.strictObject({
  id: z.string(),
  name: z.string(),
  email: z.string(),
  phone: z.string().nullable(),
});

export const authResponseSchema = z.strictObject({
  user: userResponseSchema,
  accessToken: z.string(),
  refreshToken: z.string(),
});

export const tokenPairResponseSchema = z.strictObject({
  accessToken: z.string(),
  refreshToken: z.string(),
});
