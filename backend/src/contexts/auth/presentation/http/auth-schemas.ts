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

/** Public identifier: 3-30 of `a-z 0-9 . _`, never starting or ending with a dot. */
export const USERNAME_PATTERN = /^[a-z0-9_](?:[a-z0-9._]{1,28})[a-z0-9_]$/;

export const usernameSchema = z.string().trim().toLowerCase().regex(USERNAME_PATTERN);

/** Six digits, as typed by the person. */
const codeSchema = z.string().regex(/^[0-9]{6}$/);

// ---- Requests (strict: unknown keys are rejected) ----

export const loginRequestSchema = z.strictObject({
  email: emailSchema,
  // The policy is not enforced on login so existing accounts are never locked out.
  password: z.string().min(1).max(PASSWORD_MAX_LENGTH),
});

/** Step 1 and "send again": the address that will receive the code. */
export const signUpEmailRequestSchema = z.strictObject({ email: emailSchema });

/** Step 2: the address plus the code received. */
export const verifyCodeRequestSchema = z.strictObject({ email: emailSchema, code: codeSchema });

export const usernameQuerySchema = z.strictObject({ username: usernameSchema });

/** Final step: the e-mail comes from the confirmed `verificationToken`, never from the body. */
export const registerRequestSchema = z.strictObject({
  verificationToken: z.string().min(1).max(256),
  name: z.string().trim().min(1).max(100),
  username: usernameSchema,
  password: passwordPolicySchema,
});

const refreshTokenSchema = z.string().min(1).max(512);

export const refreshRequestSchema = z.strictObject({ refreshToken: refreshTokenSchema });
export const logoutRequestSchema = z.strictObject({ refreshToken: refreshTokenSchema });

// ---- Responses (also used by the contract tests and the OpenAPI document) ----

export const userResponseSchema = z.strictObject({
  id: z.string(),
  name: z.string(),
  email: z.string(),
  username: z.string(),
  hasAvatar: z.boolean(),
});

export const verificationResponseSchema = z.strictObject({ verificationToken: z.string() });

export const usernameAvailabilityResponseSchema = z.strictObject({ available: z.boolean() });

export const authResponseSchema = z.strictObject({
  user: userResponseSchema,
  accessToken: z.string(),
  refreshToken: z.string(),
});

export const tokenPairResponseSchema = z.strictObject({
  accessToken: z.string(),
  refreshToken: z.string(),
});
