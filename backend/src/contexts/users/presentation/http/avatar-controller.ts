import type { RequestHandler } from 'express';
import { requireAuth } from '../../../auth/presentation/http/authenticate.js';
import type { GetUserAvatar, SetUserAvatar } from '../../application/avatar-use-cases.js';

export interface UserUseCases {
  readonly setAvatar: SetUserAvatar;
  readonly getAvatar: GetUserAvatar;
}

/** Only the owner can read or replace the picture: the id always comes from the token. */
export class AvatarController {
  constructor(private readonly useCases: UserUseCases) {}

  readonly put: RequestHandler = async (req, res) => {
    const { userId } = requireAuth(req);
    // express.raw leaves `{}` when there is no body.
    const body: unknown = req.body;
    await this.useCases.setAvatar.execute(userId, Buffer.isBuffer(body) ? body : new Uint8Array(0));
    res.status(204).end();
  };

  readonly get: RequestHandler = async (req, res) => {
    const { userId } = requireAuth(req);
    const picture = await this.useCases.getAvatar.execute(userId);
    res
      .status(200)
      // Always served as a JPEG that the browser must not reinterpret.
      .set({
        'Content-Type': 'image/jpeg',
        'X-Content-Type-Options': 'nosniff',
        'Cache-Control': 'private, no-store',
      })
      .send(Buffer.from(picture));
  };
}
