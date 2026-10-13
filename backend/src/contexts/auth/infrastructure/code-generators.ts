import { randomInt } from 'node:crypto';
import type {
  ConfirmationCodeGenerator,
  ConfirmationCodeSender,
} from '../domain/confirmation-code.js';

/** Always returns the same code: the demo has no e-mail provider. */
export class FixedConfirmationCodeGenerator implements ConfirmationCodeGenerator {
  constructor(private readonly code: string) {}

  generate(): string {
    return this.code;
  }
}

/** Six random digits from a CSPRNG. */
export class RandomConfirmationCodeGenerator implements ConfirmationCodeGenerator {
  generate(): string {
    return randomInt(0, 1_000_000).toString().padStart(6, '0');
  }
}

/** Delivers nothing; replace with an e-mail adapter when a provider exists. */
export class NoopConfirmationCodeSender implements ConfirmationCodeSender {
  send(): Promise<void> {
    return Promise.resolve();
  }
}
