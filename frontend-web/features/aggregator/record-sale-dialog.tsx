"use client";

import { useEffect } from "react";
import { useForm, Controller } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Field,
  FieldLabel,
  FieldError,
  FieldGroup,
  FieldDescription,
} from "@/components/ui/field";
import { PriceTag } from "@/components/shared/price-tag";
import { useRecordSaleMutation } from "@/hooks/useAggregatorCollection";
import { AGGREGATOR_CYCLE_MONTHS } from "@/lib/pricing";
import { formatINR } from "@/lib/utils";
import type { AggregatorHolding } from "@/types/aggregator";
import type { ArtworkSummary } from "@/types/artwork";

const recordSaleSchema = z.object({
  soldPrice: z
    .number({ message: "Enter the sold price" })
    .positive("Enter a valid price"),
  buyerName: z.string().min(2, "Enter the buyer's name"),
  buyerEmail: z.string().email("Enter a valid email"),
  buyerPhone: z.string().min(10, "Enter a valid phone number"),
  line1: z.string().min(3, "Enter the address"),
  city: z.string().min(2, "Enter the city"),
  state: z.string().min(2, "Enter the state"),
  pincode: z.string().regex(/^\d{6}$/, "Enter a valid 6-digit pincode"),
  paymentRoute: z.enum(["direct_to_galleryzone", "cash_at_premises"], {
    message: "Choose how the buyer paid",
  }),
  deliveryMode: z.enum(["courier", "self_pickup"], {
    message: "Select a delivery mode",
  }),
});
type RecordSaleFormValues = z.infer<typeof recordSaleSchema>;

const BLANK_BUYER_FIELDS = {
  buyerName: "",
  buyerEmail: "",
  buyerPhone: "",
  line1: "",
  city: "",
  state: "",
  pincode: "",
  paymentRoute: "direct_to_galleryzone",
  deliveryMode: "courier",
} as const;

interface RecordSaleDialogProps {
  holding: (AggregatorHolding & { artwork: ArtworkSummary }) | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

// Fields match POST /aggregators/sale's payload one-for-one (SAD §3.5,
// types/aggregator.ts's RecordSalePayload) -- soldPrice/buyer details/
// delivery address+mode -- with deliveryAddress's four sub-fields flattened
// for the form and re-nested on submit.
export function RecordSaleDialog({
  holding,
  open,
  onOpenChange,
}: RecordSaleDialogProps) {
  const router = useRouter();
  const recordSaleMutation = useRecordSaleMutation();

  const { control, handleSubmit, reset } = useForm<RecordSaleFormValues>({
    resolver: zodResolver(recordSaleSchema),
    defaultValues: { soldPrice: 0, ...BLANK_BUYER_FIELDS },
  });

  useEffect(() => {
    // Always the holding's own selling price. The field used to be editable,
    // but every ledger posting for the sale settles on the display price, so
    // a different number here would only make the sale record and the money
    // disagree -- the API refuses it. The price is set once, when reserving.
    if (open && holding) {
      reset({ soldPrice: holding.displayPrice, ...BLANK_BUYER_FIELDS });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, holding?.id, reset]);

  if (!holding) return null;

  function onSubmit(values: RecordSaleFormValues) {
    if (!holding) return;
    recordSaleMutation.mutate(
      {
        artworkId: holding.artworkId,
        soldPrice: values.soldPrice,
        buyerName: values.buyerName,
        buyerEmail: values.buyerEmail,
        buyerPhone: values.buyerPhone,
        deliveryAddress: {
          line1: values.line1,
          city: values.city,
          state: values.state,
          pincode: values.pincode,
        },
        paymentRoute: values.paymentRoute,
        deliveryMode: values.deliveryMode,
      },
      {
        onSuccess: () => {
          toast.success("Sale recorded", {
            description: `"${holding.artwork.title}" is now pending settlement. The buyer's purchase is held against ${values.buyerEmail} — it appears in their collection when they sign up with that address.`,
            action: {
              label: "Settlements",
              onClick: () => router.push("/aggregator/settlements"),
            },
          });
          onOpenChange(false);
        },
        onError: (error) => {
          toast.error(error.message);
        },
      },
    );
  }

  return (
    <Dialog
      open={open}
      onOpenChange={(next) => {
        if (!recordSaleMutation.isPending) onOpenChange(next);
      }}
    >
      <DialogContent className="max-h-[85vh] overflow-y-auto sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Record sale</DialogTitle>
          <DialogDescription>
            &ldquo;{holding.artwork.title}&rdquo; &mdash; matches the buyer and
            delivery details used to confirm this sale.
          </DialogDescription>
        </DialogHeader>

        <div className="flex flex-col gap-2 rounded-md border border-gold/25 bg-gold/5 px-3.5 py-3 text-sm">
          <div className="flex items-center justify-between">
            <p className="font-medium text-foreground">
              Month {holding.cycleMonth ?? 1} of {AGGREGATOR_CYCLE_MONTHS}
              &nbsp;display price
            </p>
            <PriceTag amount={holding.displayPrice} className="text-sm" />
          </div>
          <div className="flex items-center justify-between border-t border-gold/20 pt-2">
            <div>
              <p className="font-medium text-foreground">
                Advance ({holding.advancePercent}%) + delivery
              </p>
              <p className="mt-0.5 text-xs text-muted-foreground">
                Set off against this sale, not credited separately
              </p>
            </div>
            <span className="font-mono tabular-nums text-foreground">
              {formatINR(
                holding.advanceAmount + (holding.deliveryDeposit ?? 0),
              )}
            </span>
          </div>
          <p className="text-xs text-muted-foreground">
            Your 20% commission on the markup settles separately once
            delivery is confirmed.
          </p>
        </div>

        <form
          id="record-sale-form"
          onSubmit={handleSubmit(onSubmit)}
          className="flex flex-col gap-5"
        >
          <FieldGroup className="gap-4">
            <Controller
              control={control}
              name="soldPrice"
              render={({ field, fieldState }) => (
                <Field data-invalid={fieldState.invalid}>
                  <FieldLabel htmlFor="soldPrice">Sold price (₹)</FieldLabel>
                  <Input
                    id="soldPrice"
                    type="number"
                    readOnly
                    className="h-10 bg-muted/40"
                    value={field.value || ""}
                    onBlur={field.onBlur}
                    aria-invalid={fieldState.invalid}
                  />
                  <FieldDescription>
                    This piece&rsquo;s selling price, including GST. It was
                    set when you reserved the piece.
                  </FieldDescription>
                  <FieldError errors={[fieldState.error]} />
                </Field>
              )}
            />

            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <Controller
                control={control}
                name="buyerName"
                render={({ field, fieldState }) => (
                  <Field data-invalid={fieldState.invalid}>
                    <FieldLabel htmlFor="buyerName">Buyer name</FieldLabel>
                    <Input
                      id="buyerName"
                      className="h-10"
                      {...field}
                      aria-invalid={fieldState.invalid}
                    />
                    <FieldError errors={[fieldState.error]} />
                  </Field>
                )}
              />
              <Controller
                control={control}
                name="buyerPhone"
                render={({ field, fieldState }) => (
                  <Field data-invalid={fieldState.invalid}>
                    <FieldLabel htmlFor="buyerPhone">Buyer phone</FieldLabel>
                    <Input
                      id="buyerPhone"
                      className="h-10"
                      {...field}
                      aria-invalid={fieldState.invalid}
                    />
                    <FieldError errors={[fieldState.error]} />
                  </Field>
                )}
              />
            </div>

            <Controller
              control={control}
              name="buyerEmail"
              render={({ field, fieldState }) => (
                <Field data-invalid={fieldState.invalid}>
                  <FieldLabel htmlFor="buyerEmail">Buyer email</FieldLabel>
                  <Input
                    id="buyerEmail"
                    type="email"
                    className="h-10"
                    {...field}
                    aria-invalid={fieldState.invalid}
                  />
                  <FieldError errors={[fieldState.error]} />
                </Field>
              )}
            />

            <Controller
              control={control}
              name="line1"
              render={({ field, fieldState }) => (
                <Field data-invalid={fieldState.invalid}>
                  <FieldLabel htmlFor="line1">Delivery address</FieldLabel>
                  <Input
                    id="line1"
                    className="h-10"
                    {...field}
                    aria-invalid={fieldState.invalid}
                  />
                  <FieldError errors={[fieldState.error]} />
                </Field>
              )}
            />

            <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
              <Controller
                control={control}
                name="city"
                render={({ field, fieldState }) => (
                  <Field data-invalid={fieldState.invalid}>
                    <FieldLabel htmlFor="city">City</FieldLabel>
                    <Input
                      id="city"
                      className="h-10"
                      {...field}
                      aria-invalid={fieldState.invalid}
                    />
                    <FieldError errors={[fieldState.error]} />
                  </Field>
                )}
              />
              <Controller
                control={control}
                name="state"
                render={({ field, fieldState }) => (
                  <Field data-invalid={fieldState.invalid}>
                    <FieldLabel htmlFor="state">State</FieldLabel>
                    <Input
                      id="state"
                      className="h-10"
                      {...field}
                      aria-invalid={fieldState.invalid}
                    />
                    <FieldError errors={[fieldState.error]} />
                  </Field>
                )}
              />
              <Controller
                control={control}
                name="pincode"
                render={({ field, fieldState }) => (
                  <Field data-invalid={fieldState.invalid}>
                    <FieldLabel htmlFor="pincode">Pincode</FieldLabel>
                    <Input
                      id="pincode"
                      inputMode="numeric"
                      maxLength={6}
                      className="h-10"
                      {...field}
                      aria-invalid={fieldState.invalid}
                    />
                    <FieldError errors={[fieldState.error]} />
                  </Field>
                )}
              />
            </div>

            <Controller
              control={control}
              name="deliveryMode"
              render={({ field, fieldState }) => (
                <Field data-invalid={fieldState.invalid}>
                  <FieldLabel htmlFor="deliveryMode">Delivery mode</FieldLabel>
                  <Select
                    value={field.value}
                    onValueChange={(value) => field.onChange(value)}
                  >
                    <SelectTrigger id="deliveryMode" className="h-10 w-full">
                      <SelectValue placeholder="Select delivery mode" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="courier">Courier</SelectItem>
                      <SelectItem value="self_pickup">Self pickup</SelectItem>
                    </SelectContent>
                  </Select>
                  <FieldError errors={[fieldState.error]} />
                </Field>
              )}
            />

            <Controller
              control={control}
              name="paymentRoute"
              render={({ field, fieldState }) => (
                <Field data-invalid={fieldState.invalid}>
                  <FieldLabel htmlFor="paymentRoute">
                    How did the buyer pay?
                  </FieldLabel>
                  <Select
                    value={field.value}
                    onValueChange={(value) => field.onChange(value)}
                  >
                    <SelectTrigger id="paymentRoute" className="h-10 w-full">
                      <SelectValue placeholder="Select payment method" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="direct_to_galleryzone">
                        Paid GalleryZone directly (transfer or UPI)
                      </SelectItem>
                      <SelectItem value="cash_at_premises">
                        Cash, collected by you
                      </SelectItem>
                    </SelectContent>
                  </Select>
                  {/* Cash is GalleryZone's money in the aggregator's till. Say
                      so at the moment they choose it, not at settlement. */}
                  <p className="text-xs text-muted-foreground">
                    {field.value === "cash_at_premises"
                      ? "You will owe GalleryZone the full sale amount. Your commission is settled separately."
                      : "Nothing to transfer — the money reached GalleryZone directly."}
                  </p>
                  <FieldError errors={[fieldState.error]} />
                </Field>
              )}
            />
          </FieldGroup>
        </form>

        <DialogFooter>
          <Button
            variant="outline"
            onClick={() => onOpenChange(false)}
            disabled={recordSaleMutation.isPending}
          >
            Cancel
          </Button>
          <Button
            type="submit"
            form="record-sale-form"
            disabled={recordSaleMutation.isPending}
          >
            {recordSaleMutation.isPending ? "Recording…" : "Record sale"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
