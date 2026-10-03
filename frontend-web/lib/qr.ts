import QRCode from "qrcode";
import { verifyUrlFor } from "@/lib/verify-url";

// QR generation. Rendered client-side as a PNG data URL so the same image can
// be shown in the UI (<img>) and embedded in the certificate PDF (jsPDF
// addImage) without a second encoder. Error-correction level M survives a
// printed-and-photographed label.
export async function qrDataUrl(value: string, sizePx = 320): Promise<string> {
  return QRCode.toDataURL(value, {
    errorCorrectionLevel: "M",
    margin: 1,
    width: sizePx,
    color: { dark: "#1a1612", light: "#ffffff" },
  });
}

/** The QR on an artwork's certificate and label: its public verification URL, the same one written to its NFC tag. */
export async function artworkQrDataUrl(artworkId: string, sizePx = 320): Promise<string> {
  return qrDataUrl(verifyUrlFor(artworkId), sizePx);
}
