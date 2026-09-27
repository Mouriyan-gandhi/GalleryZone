"use client";

import { useState } from "react";
import { useForm, Controller } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { CheckCircle2, MapPin, Plus } from "lucide-react";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Field,
  FieldLabel,
  FieldError,
  FieldGroup,
} from "@/components/ui/field";
import { useAddresses, useAddAddressMutation } from "@/hooks/useAddresses";
import type { Address } from "@/types/customer";

const addressSchema = z.object({
  line1: z.string().min(3, "Enter the address line"),
  line2: z.string().optional(),
  city: z.string().min(2, "Enter the city"),
  state: z.string().min(2, "Enter the state"),
  pincode: z.string().regex(/^\d{6}$/, "Enter a valid 6-digit pincode"),
  isDefault: z.boolean(),
});
type AddressFormValues = z.infer<typeof addressSchema>;

const EMPTY_VALUES: AddressFormValues = {
  line1: "",
  line2: "",
  city: "",
  state: "",
  pincode: "",
  isDefault: false,
};

interface CheckoutAddressStepProps {
  selectedAddressId: string | null;
  onSelect: (address: Address) => void;
  onContinue: () => void;
}

// Step 1 of checkout: pick a saved address or add a new one inline. Mirrors
// the Addresses account page's field set (Task 5) but as a lighter inline
// variant rather than reusing that page's Dialog component here, per the
// plan's "don't force a wrapper if it's awkward" note.
//
// customerService.addAddress never mutates the shared mockAddresses array
// (same pattern as every other mock mutation in this app), so a freshly
// added address won't show up if useAddresses() refetches — it's tracked in
// local `sessionAddresses` state instead and merged into the list for
// display/selection.
export function CheckoutAddressStep({
  selectedAddressId,
  onSelect,
  onContinue,
}: CheckoutAddressStepProps) {
  const { data: fetchedAddresses, isPending } = useAddresses();
  const [sessionAddresses, setSessionAddresses] = useState<Address[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const addAddressMutation = useAddAddressMutation();

  const addresses = [...(fetchedAddresses ?? []), ...sessionAddresses];

  const { control, handleSubmit, reset } = useForm<AddressFormValues>({
    resolver: zodResolver(addressSchema),
    defaultValues: EMPTY_VALUES,
  });

  function onSubmit(values: AddressFormValues) {
    addAddressMutation.mutate(
      { ...values, line2: values.line2 || undefined },
      {
        onSuccess: (newAddress) => {
          setSessionAddresses((prev) => [...prev, newAddress]);
          onSelect(newAddress);
          setIsAdding(false);
          reset(EMPTY_VALUES);
        },
      },
    );
  }

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h2 className="font-display text-xl font-semibold text-foreground">
          Where should we deliver this?
        </h2>
        <p className="mt-1 text-sm text-muted-foreground">
          Choose a saved address, or add a new one for this order.
        </p>
      </div>

      {isPending ? (
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
          {[0, 1].map((i) => (
            <div
              key={i}
              className="h-28 animate-pulse rounded-lg border border-border bg-muted/40"
            />
          ))}
        </div>
      ) : (
        <div
          role="radiogroup"
          aria-label="Delivery address"
          className="grid grid-cols-1 gap-3 sm:grid-cols-2"
        >
          {addresses.map((address) => {
            const selected = address.id === selectedAddressId;
            return (
              <button
                key={address.id}
                type="button"
                role="radio"
                aria-checked={selected}
                onClick={() => onSelect(address)}
                className={cn(
                  "relative flex flex-col gap-1 rounded-lg border px-4 py-3.5 text-left text-sm transition-colors",
                  selected
                    ? "border-gold/60 bg-gold/10"
                    : "border-border hover:border-gold/30 hover:bg-card",
                )}
              >
                <span className="flex items-center gap-1.5 pr-6 font-medium text-foreground">
                  <MapPin
                    className="size-3.5 shrink-0 text-gold-bright"
                    strokeWidth={1.75}
                  />
                  {address.line1}
                </span>
                {address.line2 && (
                  <span className="text-muted-foreground">{address.line2}</span>
                )}
                <span className="text-muted-foreground">
                  {address.city}, {address.state} {address.pincode}
                </span>
                {address.isDefault && (
                  <span className="mt-1 w-fit rounded-full border border-gold/40 px-2 py-0.5 text-[0.65rem] font-medium tracking-wide text-gold-bright uppercase">
                    Default
                  </span>
                )}
                {selected && (
                  <CheckCircle2
                    className="absolute top-3.5 right-3.5 size-4 text-gold-bright"
                    strokeWidth={2}
                  />
                )}
              </button>
            );
          })}
        </div>
      )}

      {!isAdding ? (
        <button
          type="button"
          onClick={() => setIsAdding(true)}
          className="inline-flex w-fit items-center gap-1.5 text-sm font-medium text-gold-bright hover:underline"
        >
          <Plus className="size-4" strokeWidth={1.75} />
          Add a new address
        </button>
      ) : (
        <form
          onSubmit={handleSubmit(onSubmit)}
          className="flex flex-col gap-4 rounded-lg border border-border bg-card p-4"
        >
          <FieldGroup className="gap-4">
            <Controller
              control={control}
              name="line1"
              render={({ field, fieldState }) => (
                <Field data-invalid={fieldState.invalid}>
                  <FieldLabel htmlFor="checkout-line1">
                    Address line 1
                  </FieldLabel>
                  <Input
                    id="checkout-line1"
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
              name="line2"
              render={({ field, fieldState }) => (
                <Field data-invalid={fieldState.invalid}>
                  <FieldLabel htmlFor="checkout-line2">
                    Address line 2 (optional)
                  </FieldLabel>
                  <Input
                    id="checkout-line2"
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
                    <FieldLabel htmlFor="checkout-city">City</FieldLabel>
                    <Input
                      id="checkout-city"
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
                    <FieldLabel htmlFor="checkout-state">State</FieldLabel>
                    <Input
                      id="checkout-state"
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
                    <FieldLabel htmlFor="checkout-pincode">Pincode</FieldLabel>
                    <Input
                      id="checkout-pincode"
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
              name="isDefault"
              render={({ field }) => (
                <label className="flex items-center gap-2.5 text-sm text-foreground">
                  <Checkbox
                    checked={field.value}
                    onCheckedChange={(checked) =>
                      field.onChange(checked === true)
                    }
                  />
                  Set as default address
                </label>
              )}
            />
          </FieldGroup>

          <div className="flex items-center gap-3">
            <Button
              type="submit"
              size="sm"
              disabled={addAddressMutation.isPending}
            >
              {addAddressMutation.isPending ? "Saving…" : "Save address"}
            </Button>
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => {
                setIsAdding(false);
                reset(EMPTY_VALUES);
              }}
              disabled={addAddressMutation.isPending}
            >
              Cancel
            </Button>
          </div>
        </form>
      )}

      <div className="flex justify-end border-t border-border pt-5">
        <Button onClick={onContinue} disabled={!selectedAddressId}>
          Continue to review
        </Button>
      </div>
    </div>
  );
}
