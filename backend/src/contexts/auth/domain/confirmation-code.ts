/** Produces the one-time code that proves ownership of an e-mail address. */
export interface ConfirmationCodeGenerator {
  generate(): string;
}

/**
 * Delivers the code to the person. The demo adapter delivers nothing (the code is fixed
 * and documented); a real e-mail provider only needs to implement this port.
 */
export interface ConfirmationCodeSender {
  send(email: string, code: string): Promise<void>;
}
