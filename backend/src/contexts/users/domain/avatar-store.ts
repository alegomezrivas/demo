/** Storage port for profile pictures (one JPEG per user). */
export interface AvatarStore {
  has(userId: string): Promise<boolean>;
  get(userId: string): Promise<Uint8Array | undefined>;
  set(userId: string, jpeg: Uint8Array): Promise<void>;
}
