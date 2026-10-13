import { AppError } from '../../../shared/errors/app-error.js';
import type { AvatarStore } from '../domain/avatar-store.js';

/** Largest accepted picture; the app recompresses to fit before uploading. */
export const AVATAR_MAX_BYTES = 200 * 1024;

/**
 * True when [bytes] look like a complete JPEG: start-of-image marker (FF D8 FF) and
 * end-of-image marker (FF D9). The declared Content-Type is never trusted.
 */
export function isJpeg(bytes: Uint8Array): boolean {
  const n = bytes.length;
  return (
    n >= 5 &&
    bytes[0] === 0xff &&
    bytes[1] === 0xd8 &&
    bytes[2] === 0xff &&
    bytes[n - 2] === 0xff &&
    bytes[n - 1] === 0xd9
  );
}

export class SetUserAvatar {
  constructor(private readonly avatars: AvatarStore) {}

  async execute(userId: string, bytes: Uint8Array): Promise<void> {
    if (bytes.length > AVATAR_MAX_BYTES) throw tooLarge();
    if (!isJpeg(bytes)) {
      throw AppError.validation([{ field: 'body', issue: 'invalid_image' }], 'invalid_image');
    }
    await this.avatars.set(userId, bytes);
  }
}

function tooLarge(): AppError {
  return AppError.validation([{ field: 'body', issue: 'image_too_large' }], 'image_too_large');
}

export class GetUserAvatar {
  constructor(private readonly avatars: AvatarStore) {}

  async execute(userId: string): Promise<Uint8Array> {
    const picture = await this.avatars.get(userId);
    if (picture === undefined) throw AppError.notFound('avatar_not_found');
    return picture;
  }
}
