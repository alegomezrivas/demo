/** Source of the current time; injected so expiry logic can be tested deterministically. */
export interface Clock {
  now(): Date;
}

export class SystemClock implements Clock {
  now(): Date {
    return new Date();
  }
}
