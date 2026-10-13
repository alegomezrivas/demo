/** Creates opaque refresh tokens and the hashes under which they are stored. */
export interface RefreshTokenGenerator {
  generate(): { readonly token: string; readonly hash: string };
  hash(token: string): string;
}
