export type OrderStatus =
  | "pending"
  | "paid"
  | "confirmed"
  | "packed"
  | "transit"
  | "delivered"
  | "cancelled";

export interface OrderStatusEvent {
  status: OrderStatus;
  changedAt: string; // ISO date
}

export interface Order {
  id: string;
  artworkId: string;
  addressId: string;
  /** Buyer's uid — present on admin reads. */
  customerId?: string;
  amount: number; // artwork's customerPrice at time of purchase
  gstAmount: number;
  deliveryCharge: number;
  /** Customer convenience fee, and the 18% service GST on it. Both 0 today. */
  convenienceFee: number;
  convenienceGst: number;
  status: OrderStatus;
  createdAt: string; // ISO date
  /** Snapshot of what was bought, joined by the API. Null if the artwork was removed. */
  artwork?: { title: string; artistName: string; artistId: string; thumbnailUrl: string; productCode: string } | null;
  statusHistory: OrderStatusEvent[];
  /** Admin reads only: the piece's NFC tag. A dispatch is refused while it is not locked (unless overridden) once the gate is on. */
  nfc?: { linked: boolean; locked: boolean; gateOverridden: boolean };
  // Payment reference from the gateway. Simulated for now (see
  // features/checkout/razorpay-simulation.tsx) — the shape matches what
  // Razorpay returns so wiring the real gateway is a swap, not a rewrite.
  payment?: {
    provider: "razorpay";
    paymentId: string;
    method: string;
    simulated: boolean;
  } | null;
}
