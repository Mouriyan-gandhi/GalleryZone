import { http } from "@/lib/api";
import type { VerifyPassport } from "./verifyService";

// GET /v1/passport/mine — the passports of the pieces the signed-in person
// owns, made or holds on display. Each entry is the same public passport a
// scan shows, plus how this person relates to the piece.

export type PassportRelation = "owner" | "artist" | "holder";

export interface MyPassport {
  relations: PassportRelation[];
  /** Only for a piece the viewer made: whether a physical tag is linked. */
  nfcLinked: boolean | null;
  /** Only for a piece the viewer holds on display: the holding to open. */
  holdingId: string | null;
  passport: VerifyPassport;
}

export interface MyPassports {
  /** Full count; `items` is capped by the API. */
  total: number;
  items: MyPassport[];
}

export const passportService = {
  mine: () => http.get<MyPassports>("/v1/passport/mine"),
};
