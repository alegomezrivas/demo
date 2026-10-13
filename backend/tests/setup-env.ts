// Test-only values; real secrets always come from the environment.
process.env['NODE_ENV'] = 'test';
process.env['LOG_LEVEL'] = 'silent';
process.env['JWT_ACCESS_SECRET'] = 'test-only-secret-test-only-secret-0123456789';
