import { FileSearch, Fingerprint, Scan, ShieldCheck, type LucideIcon } from "lucide-react";

export type PassportTopicSlug = "identity" | "certificate" | "provenance" | "legacy";

export interface PassportTopic {
  slug: PassportTopicSlug;
  title: string;
  /** One line, shared with the landing page card that links here. */
  summary: string;
  icon: LucideIcon;
  headline: string;
  lede: string;
  seoDescription: string;
  image: string;
  imageAlt: string;
  imagePosition: string;
  includesHeading: string;
  includes: { title: string; body: string }[];
  /** Something the reader should not have to guess, shown under the list. */
  note?: string;
  stepsHeading: string;
  steps: { title: string; body: string }[];
}

// Every line here describes what the product does today: the passport page
// (features/verify), the certificate PDF (features/coa) and the ownership
// ledger (backend packages/db ownership.ts). Change the product and this
// copy together.
export const PASSPORT_TOPICS: PassportTopic[] = [
  {
    slug: "identity",
    title: "Identity",
    summary: "A unique digital identity created for every artwork.",
    icon: Scan,
    headline: "Every artwork gets its own identity",
    lede: "A product ID and a QR code tie each piece to one public record. Scan the label and you see what it is, who made it and who owns it.",
    seoDescription:
      "How GalleryZone gives every original artwork a digital identity: a product ID, a QR label and a public passport anyone can open.",
    image: "/identity/identity-art.jpg",
    imageAlt: "A framed portrait hung in a gallery, with a red wax seal on the canvas",
    imagePosition: "center 40%",
    includesHeading: "What the passport shows",
    includes: [
      { title: "Who made it", body: "The artist's name, linked to their profile." },
      { title: "Who owns it", body: "The current owner of record. It changes when ownership does." },
      { title: "Where it is", body: "Who holds the piece right now, and where it is kept." },
      { title: "Its certificate", body: "The certificate number and issue date, with a PDF to download." },
    ],
    note: "Prices, contact details and addresses never appear on a passport.",
    stepsHeading: "How a piece gets its identity",
    steps: [
      { title: "Registered", body: "The artist lists the piece and it receives a product ID." },
      { title: "Reviewed", body: "GalleryZone checks the listing before it goes live." },
      { title: "Labelled", body: "A QR code that opens the passport goes on the piece's label." },
      { title: "Scanned", body: "Anyone with a phone can open the passport. No account needed." },
    ],
  },
  {
    slug: "certificate",
    title: "Certificate",
    summary: "Verified authenticity and ownership, digitally secured.",
    icon: ShieldCheck,
    headline: "A numbered certificate for every piece",
    lede: "When GalleryZone approves an artwork, it issues a Certificate of Authenticity with its own number. You can download it any time.",
    seoDescription:
      "Every approved artwork on GalleryZone gets a numbered Certificate of Authenticity, downloadable as a PDF, with a hand-signed paper copy on request.",
    image: "/identity/certificate-art.png",
    imageAlt: "A blank certificate with a gold seal, standing beside an abstract painting",
    imagePosition: "35% center",
    includesHeading: "What the certificate states",
    includes: [
      {
        title: "A number and a date",
        body: "Each certificate has its own number, like GZ-COA-2026-0002, and the date GalleryZone approved the listing.",
      },
      { title: "The work's details", body: "Title, artist, category, medium, size and year." },
      { title: "The current owner", body: "The owner of record on the day you download it." },
      { title: "A QR code", body: "It opens the passport, so anyone can check a printed copy." },
    ],
    note: "The PDF shows the record on the day you download it. The hand-signed paper certificate is its physical counterpart.",
    stepsHeading: "How you get yours",
    steps: [
      { title: "Approved", body: "GalleryZone approves the listing and issues the number." },
      { title: "Downloaded", body: "Open the passport and download the PDF whenever you need it." },
      { title: "Signed on paper", body: "Buyers can request a hand-signed copy from the artist." },
      { title: "Checked", body: "Scan the QR code on any copy to compare it with the record." },
    ],
  },
  {
    slug: "provenance",
    title: "Provenance",
    summary: "A transparent record of every ownership and transfer.",
    icon: FileSearch,
    headline: "A record of every owner and every move",
    lede: "Provenance is a piece's history. GalleryZone writes it down as it happens and shows it on the passport for anyone to read.",
    seoDescription:
      "How GalleryZone records ownership: every hand-over, every display loan and the current owner, on a public passport.",
    image: "/identity/provenance-art.jpg",
    imageAlt: "A certificate of provenance on a desk beside a framed portrait",
    imagePosition: "center",
    includesHeading: "What gets recorded",
    includes: [
      {
        title: "Every hand-over",
        body: "Who gave the piece, who received it and when, and whether it was a sale on GalleryZone.",
      },
      {
        title: "Display loans",
        body: "A piece lent to a gallery is marked as a loan, not a sale, and ends on its date.",
      },
      { title: "The owner of record", body: "The passport always names the current owner." },
      { title: "Where it is", body: "Who holds the piece and where it is kept, shown next to the owner." },
    ],
    note: "GalleryZone's own server writes ownership changes, and only after the receiving person accepts.",
    stepsHeading: "How a hand-over is recorded",
    steps: [
      { title: "Started", body: "The owner names the person who will receive the piece." },
      { title: "Sent", body: "The receiver gets a link that shows the piece and who is handing it over." },
      { title: "Accepted", body: "They accept, and become the owner of record." },
      { title: "Added", body: "The passport gains a new entry. Earlier entries stay." },
    ],
  },
  {
    slug: "legacy",
    title: "Legacy",
    summary: "Preserving your artwork's story for future generations.",
    icon: Fingerprint,
    headline: "The story stays with the piece",
    lede: "Owners change. The record does not start again. Each new owner inherits the passport, and the artist's name stays on it.",
    seoDescription:
      "Why a GalleryZone passport lasts across owners: the artist stays on the record and every resale adds to it.",
    image: "/identity/legacy-art.png",
    imageAlt: "An archive room with a large framed abstract painting on the wall",
    imagePosition: "center",
    includesHeading: "What carries forward",
    includes: [
      { title: "The artist's name", body: "Every passport says who made the piece and links to their profile." },
      { title: "A chain that only grows", body: "A resale adds an entry. It never replaces an earlier one." },
      { title: "The same code", body: "The QR on the label keeps opening the current passport, whoever owns the piece." },
      { title: "A copy for the owner", body: "The certificate PDF can be downloaded again whenever it is needed." },
    ],
    stepsHeading: "A piece over time",
    steps: [
      { title: "Made", body: "The artist registers the piece and its certificate is issued." },
      { title: "Sold", body: "A sale on GalleryZone makes the buyer the owner of record." },
      { title: "Handed on", body: "The owner can resell or gift it. The receiver accepts a transfer link." },
      { title: "Read", body: "The next owner scans the label and sees the chain from the artist to today." },
    ],
  },
];

export function getPassportTopic(slug: string): PassportTopic | undefined {
  return PASSPORT_TOPICS.find((topic) => topic.slug === slug);
}
