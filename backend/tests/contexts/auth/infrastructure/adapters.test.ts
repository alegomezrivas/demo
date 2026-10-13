import { describe, expect, it } from 'vitest';
import { Argon2PasswordHasher } from '../../../../src/contexts/auth/infrastructure/argon2-password-hasher.js';
import { CryptoRefreshTokenGenerator } from '../../../../src/contexts/auth/infrastructure/crypto-refresh-token-generator.js';
import { InMemoryRefreshTokenRepository } from '../../../../src/contexts/auth/infrastructure/in-memory-refresh-token-repository.js';
import { InMemoryUserRepository } from '../../../../src/contexts/auth/infrastructure/in-memory-user-repository.js';
import { JoseAccessTokenService } from '../../../../src/contexts/auth/infrastructure/jose-access-token-service.js';
import { passwordPolicySchema } from '../../../../src/contexts/auth/presentation/http/auth-schemas.js';
import { FakeClock, fastHasher, TEST_SECRET } from '../../../helpers/test-app.js';

describe('Argon2PasswordHasher', () => {
  it('hashes with argon2id and verifies only the right password', async () => {
    const hash = await fastHasher.hash('Str0ng!Pass');
    expect(hash.startsWith('$argon2id$')).toBe(true);
    expect(hash).not.toContain('Str0ng');
    expect(await fastHasher.verify(hash, 'Str0ng!Pass')).toBe(true);
    expect(await fastHasher.verify(hash, 'other')).toBe(false);
  });

  it('salts every hash', async () => {
    expect(await fastHasher.hash('same')).not.toBe(await fastHasher.hash('same'));
  });

  it('treats a malformed stored hash as a mismatch', async () => {
    expect(await fastHasher.verify('garbage', 'x')).toBe(false);
  });

  it('works with the default parameters', async () => {
    const hasher = new Argon2PasswordHasher();
    expect(await hasher.verify(await hasher.hash('x'), 'x')).toBe(true);
  });
});

describe('JoseAccessTokenService', () => {
  const clock = new FakeClock();
  const service = new JoseAccessTokenService(TEST_SECRET, 60, clock);

  it('round-trips the user id', async () => {
    const claims = await service.verify(await service.issue('user-9'));
    expect(claims).toMatchObject({ userId: 'user-9', refreshed: false });
    expect(claims.tokenId).toMatch(/^[0-9a-f-]{36}$/);
  });

  it('marks tokens minted by a refresh', async () => {
    const token = await service.issue('user-9', { refreshed: true });
    expect((await service.verify(token)).refreshed).toBe(true);
  });

  it('flags expiry with token_expired', async () => {
    const token = await service.issue('user-9');
    clock.advanceSeconds(61);
    await expect(service.verify(token)).rejects.toMatchObject({
      kind: 'unauthorized',
      code: 'token_expired',
    });
  });

  it('rejects tampered tokens', async () => {
    const token = await service.issue('user-9');
    const tampered = `${token.slice(0, -2)}xx`;
    await expect(service.verify(tampered)).rejects.toMatchObject({ code: 'unauthorized' });
  });

  it('issues unique tokens (jti)', async () => {
    expect(await service.issue('u')).not.toBe(await service.issue('u'));
  });
});

describe('CryptoRefreshTokenGenerator', () => {
  const generator = new CryptoRefreshTokenGenerator();

  it('generates unguessable unique tokens and a stable hash', () => {
    const a = generator.generate();
    const b = generator.generate();
    expect(a.token).not.toBe(b.token);
    expect(a.token.length).toBeGreaterThanOrEqual(64);
    expect(a.hash).toBe(generator.hash(a.token));
    expect(a.hash).not.toContain(a.token);
    expect(a.hash).toMatch(/^[0-9a-f]{64}$/);
  });
});

describe('InMemoryRefreshTokenRepository', () => {
  const record = (overrides: object = {}) => ({
    id: 'r1',
    familyId: 'f1',
    userId: 'u1',
    tokenHash: 'h1',
    expiresAt: new Date('2030-01-01'),
    usedAt: null,
    revokedAt: null,
    ...overrides,
  });

  it('consumes a token exactly once, even when raced', async () => {
    const repo = new InMemoryRefreshTokenRepository();
    await repo.save(record());
    const results = await Promise.all([
      repo.consume('r1', new Date()),
      repo.consume('r1', new Date()),
    ]);
    expect(results.filter(Boolean)).toHaveLength(1);
  });

  it('refuses to consume revoked or unknown tokens', async () => {
    const repo = new InMemoryRefreshTokenRepository();
    await repo.save(record());
    await repo.revokeFamily('f1', new Date());
    expect(await repo.consume('r1', new Date())).toBe(false);
    expect(await repo.consume('missing', new Date())).toBe(false);
  });

  it('only revokes the requested family', async () => {
    const repo = new InMemoryRefreshTokenRepository();
    await repo.save(record());
    await repo.save(record({ id: 'r2', familyId: 'f2', tokenHash: 'h2' }));
    await repo.revokeFamily('f1', new Date());
    expect((await repo.findByHash('h1'))?.revokedAt).not.toBeNull();
    expect((await repo.findByHash('h2'))?.revokedAt).toBeNull();
  });

  it('forgets everything on clear', async () => {
    const repo = new InMemoryRefreshTokenRepository();
    await repo.save(record());
    repo.clear();
    expect(await repo.findByHash('h1')).toBeUndefined();
  });
});

describe('InMemoryUserRepository', () => {
  const user = { id: 'u1', name: 'A', email: 'a@x.com', phone: null, passwordHash: 'h' };

  it('enforces unique e-mails', async () => {
    const repo = new InMemoryUserRepository();
    expect(await repo.add(user)).toBe(true);
    expect(await repo.add({ ...user, id: 'u2' })).toBe(false);
    expect(await repo.findByEmail('a@x.com')).toEqual(user);
    expect(await repo.findById('u2')).toBeUndefined();
    expect(await repo.findByEmail('b@x.com')).toBeUndefined();
  });
});

describe('passwordPolicySchema', () => {
  it.each(['Str0ng!Pass', 'Aa1!aaaa', 'Zz9$' + 'x'.repeat(124)])('accepts %j', (value) => {
    expect(passwordPolicySchema.safeParse(value).success).toBe(true);
  });

  it.each([
    ['Sh0rt!a', 'too short'],
    ['alllowercase1!', 'no uppercase'],
    ['ALLUPPERCASE1!', 'no lowercase'],
    ['NoDigits!!!', 'no digit'],
    ['NoSymbols123', 'no symbol'],
    ['Aa1!' + 'x'.repeat(125), 'too long'],
  ])('rejects %j (%s)', (value) => {
    expect(passwordPolicySchema.safeParse(value).success).toBe(false);
  });
});
