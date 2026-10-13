import type { AvatarStore } from '../domain/avatar-store.js';

/** Keeps pictures in memory; they are lost on restart like every other demo datum. */
export class InMemoryAvatarStore implements AvatarStore {
  private readonly pictures = new Map<string, Uint8Array>();

  has(userId: string): Promise<boolean> {
    return Promise.resolve(this.pictures.has(userId));
  }

  get(userId: string): Promise<Uint8Array | undefined> {
    return Promise.resolve(this.pictures.get(userId));
  }

  set(userId: string, jpeg: Uint8Array): Promise<void> {
    this.pictures.set(userId, jpeg);
    return Promise.resolve();
  }

  clear(): void {
    this.pictures.clear();
  }
}
