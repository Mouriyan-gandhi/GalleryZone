"use client";

import { useState, type FormEvent } from "react";
import { motion } from "framer-motion";
import {
  Wallet,
  ArrowDownRight,
  ArrowUpRight,
  Landmark,
  Check,
} from "lucide-react";
import { EmptyState } from "@/components/shared/empty-state";
import {
  useCustomerWallet,
  useCustomerWalletTransactions,
} from "@/hooks/useCustomerWallet";
import type { WalletTransaction } from "@/features/dashboard/dashboard-data";
import {
  useCustomerProfile,
  useUpdateProfileMutation,
} from "@/hooks/useCustomerProfile";
import { useCustomerWithdrawalMutation } from "@/hooks/useCustomerWallet";
import { MIN_CUSTOMER_WITHDRAWAL } from "@/services/customerWalletService";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import type { CustomerProfile } from "@/types/customer";
import { GstNumberCard } from "@/components/shared/gst-number-card";

// Store credit here is refunds and resale proceeds — the collector's own
// money, so it can leave. Withdrawal appears only once there is a balance AND
// somewhere to send it, which keeps an account that has never had either
// looking as simple as it did before.
export function CollectorWalletOverview() {
  const { data: wallet } = useCustomerWallet();
  const { data: transactions } = useCustomerWalletTransactions();
  const { data: profile } = useCustomerProfile();
  const updateProfileMutation = useUpdateProfileMutation();

  return (
    <div className="flex flex-col gap-6">
      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, ease: "easeOut" }}
        className="flex flex-col gap-1 rounded-lg border border-gold/30 bg-gold/5 p-6"
      >
        <div className="flex items-center gap-2">
          <Wallet className="size-4 text-gold-bright" strokeWidth={1.75} />
          <span className="text-sm text-muted-foreground">Store credit</span>
        </div>
        <p className="font-display text-3xl font-semibold tabular-nums text-foreground">
          ₹{(wallet?.balance ?? 0).toLocaleString("en-IN")}
        </p>
        <p className="mt-1 text-xs text-muted-foreground">
          Refunds, cancellations and resale proceeds credit here automatically,
          and apply at your next checkout. Or take it out to your bank.
        </p>

        <WithdrawRow
          balance={wallet?.balance ?? 0}
          hasBankDetails={Boolean(profile?.bankAccountNumber)}
        />
      </motion.div>

      <div className="rounded-lg border border-border bg-card p-5 sm:p-6">
        <h2 className="font-display text-base font-semibold text-foreground">
          Transaction history
        </h2>

        <div className="mt-3 flex flex-col">
          {!transactions || transactions.length === 0 ? (
            <EmptyState
              icon={Wallet}
              title="No transactions yet"
              description="Refunds and store credit adjustments will show up here."
              className="border-0 py-10"
            />
          ) : (
            transactions.map((tx) => <TransactionRow key={tx.id} tx={tx} />)
          )}
        </div>
      </div>
      {profile && <BankDetailsCard profile={profile} />}

      {profile && (
        <GstNumberCard
          value={profile.gstin ?? ""}
          onSave={(gstin) => updateProfileMutation.mutate({ gstin })}
          isPending={updateProfileMutation.isPending}
          isSuccess={updateProfileMutation.isSuccess}
          description="Add it if you need GST invoices for your purchases — for a business or an office collection, say."
        />
      )}
    </div>
  );
}

// Sits inside the balance card rather than in a card of its own: taking money
// out is a thing you do to the number you are looking at, not a separate task.
function WithdrawRow({
  balance,
  hasBankDetails,
}: {
  balance: number;
  hasBankDetails: boolean;
}) {
  const withdraw = useCustomerWithdrawalMutation();
  const [amount, setAmount] = useState("");
  const amountNumber = Number(amount) || 0;

  const belowMinimum = amount !== "" && amountNumber < MIN_CUSTOMER_WITHDRAWAL;
  const exceedsBalance = amountNumber > balance;
  const canSubmit =
    hasBankDetails &&
    amountNumber >= MIN_CUSTOMER_WITHDRAWAL &&
    !exceedsBalance;

  if (balance <= 0) return null;

  return (
    <div className="mt-4 flex flex-col gap-2 border-t border-gold/20 pt-4">
      {!hasBankDetails ? (
        <p className="text-xs text-muted-foreground">
          Add your bank account below to take this out. Until then it stays as
          credit towards your next purchase.
        </p>
      ) : (
        <>
          <div className="flex flex-wrap items-center gap-2">
            <Input
              aria-label="Amount to withdraw"
              type="number"
              min={MIN_CUSTOMER_WITHDRAWAL}
              placeholder={String(MIN_CUSTOMER_WITHDRAWAL)}
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              className="h-9 w-32"
            />
            <button
              type="button"
              disabled={!canSubmit || withdraw.isPending}
              onClick={() =>
                withdraw.mutate(amountNumber, {
                  onSuccess: () => setAmount(""),
                })
              }
              className="inline-flex h-9 items-center rounded-md border border-gold/50 px-4 text-sm font-medium text-gold-bright transition-colors hover:border-gold hover:bg-gold/10 disabled:pointer-events-none disabled:opacity-40"
            >
              {withdraw.isPending ? "Sending…" : "Withdraw"}
            </button>
          </div>
          <p className="text-xs text-muted-foreground">
            {exceedsBalance
              ? "That is more than your balance."
              : belowMinimum
                ? `Minimum ₹${MIN_CUSTOMER_WITHDRAWAL.toLocaleString("en-IN")}.`
                : `Minimum ₹${MIN_CUSTOMER_WITHDRAWAL.toLocaleString("en-IN")} · reaches your bank in 2–3 working days.`}
          </p>
        </>
      )}
      {withdraw.isError && (
        <p className="text-xs text-destructive">{withdraw.error.message}</p>
      )}
    </div>
  );
}

// IFSC is four letters, a zero, then six characters identifying the branch.
const IFSC_PATTERN = /^[A-Z]{4}0[A-Z0-9]{6}$/;

// Buyers pay in far more often than they take money out, so this stays
// optional and out of the way — until there is a balance sitting here, at
// which point not being able to reach it is the whole problem.
function BankDetailsCard({ profile }: { profile: CustomerProfile }) {
  const updateProfile = useUpdateProfileMutation();
  const [form, setForm] = useState({
    bankAccountName: profile.bankAccountName ?? "",
    bankAccountNumber: profile.bankAccountNumber ?? "",
    bankIfsc: profile.bankIfsc ?? "",
  });

  const ifsc = form.bankIfsc.trim().toUpperCase();
  const ifscInvalid = ifsc.length > 0 && !IFSC_PATTERN.test(ifsc);
  const accountInvalid =
    form.bankAccountNumber.trim().length > 0 &&
    form.bankAccountNumber.trim().length < 9;
  const complete =
    form.bankAccountName.trim() !== "" &&
    !accountInvalid &&
    form.bankAccountNumber.trim() !== "" &&
    IFSC_PATTERN.test(ifsc);

  function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (!complete) return;
    updateProfile.mutate({
      bankAccountName: form.bankAccountName.trim(),
      bankAccountNumber: form.bankAccountNumber.trim(),
      bankIfsc: ifsc,
    });
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="flex flex-col gap-4 rounded-lg border border-border bg-card p-5 sm:p-6"
    >
      <div className="flex items-start gap-3">
        <span className="flex size-9 shrink-0 items-center justify-center rounded-full border border-gold/30 bg-background">
          <Landmark className="size-4 text-gold-bright" strokeWidth={1.75} />
        </span>
        <div>
          <h2 className="font-display text-base font-semibold text-foreground">
            Bank account{" "}
            <span className="text-sm font-normal text-muted-foreground">
              (optional)
            </span>
          </h2>
          <p className="mt-0.5 text-sm leading-relaxed text-muted-foreground">
            Only needed if you want money sent back to you — a refund you would
            rather have than store credit, or what you are paid when you resell
            a piece from your collection.
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div className="flex flex-col gap-2 sm:col-span-2">
          <Label htmlFor="bankAccountName">Account holder name</Label>
          <Input
            id="bankAccountName"
            placeholder="As printed on your passbook"
            value={form.bankAccountName}
            onChange={(e) =>
              setForm((prev) => ({ ...prev, bankAccountName: e.target.value }))
            }
            className="h-10"
          />
        </div>

        <div className="flex flex-col gap-2">
          <Label htmlFor="bankAccountNumber">Account number</Label>
          <Input
            id="bankAccountNumber"
            inputMode="numeric"
            maxLength={18}
            placeholder="00000000000000"
            value={form.bankAccountNumber}
            onChange={(e) =>
              setForm((prev) => ({
                ...prev,
                bankAccountNumber: e.target.value.replace(/[^0-9]/g, ""),
              }))
            }
            aria-invalid={accountInvalid}
            className="h-10 font-mono"
          />
          {accountInvalid && (
            <p className="text-xs text-destructive">
              That looks too short for an account number.
            </p>
          )}
        </div>

        <div className="flex flex-col gap-2">
          <Label htmlFor="bankIfsc">IFSC code</Label>
          <Input
            id="bankIfsc"
            maxLength={11}
            placeholder="HDFC0001234"
            value={form.bankIfsc}
            onChange={(e) =>
              setForm((prev) => ({
                ...prev,
                bankIfsc: e.target.value.toUpperCase(),
              }))
            }
            aria-invalid={ifscInvalid}
            className="h-10 font-mono"
          />
          {ifscInvalid ? (
            <p className="text-xs text-destructive">
              An IFSC is eleven characters, like HDFC0001234.
            </p>
          ) : (
            <p className="text-xs text-muted-foreground">
              Printed on your cheque book and in your banking app.
            </p>
          )}
        </div>
      </div>

      <div className="flex items-center gap-3">
        <button
          type="submit"
          disabled={!complete || updateProfile.isPending}
          className="inline-flex items-center gap-2 rounded-md border border-gold/50 px-5 py-2.5 text-sm font-medium text-gold-bright transition-colors hover:border-gold hover:bg-gold/10 disabled:pointer-events-none disabled:opacity-40"
        >
          {profile.bankAccountNumber ? "Update bank account" : "Save bank account"}
        </button>
        {updateProfile.isSuccess && (
          <span className="flex items-center gap-1.5 text-sm text-gold-bright">
            <Check className="size-3.5" />
            Saved
          </span>
        )}
      </div>
    </form>
  );
}

function TransactionRow({ tx }: { tx: WalletTransaction }) {
  const isCredit = tx.amount >= 0;
  const Icon = isCredit ? ArrowUpRight : ArrowDownRight;

  return (
    <div className="flex items-center justify-between gap-3 border-b border-border py-3 last:border-b-0">
      <div className="flex min-w-0 items-center gap-2.5">
        <span
          className={`flex size-7 shrink-0 items-center justify-center rounded-full ${
            isCredit
              ? "bg-emerald-500/10 text-emerald-400"
              : "bg-secondary text-muted-foreground"
          }`}
        >
          <Icon className="size-3.5" />
        </span>
        <div className="min-w-0">
          <p className="truncate text-sm text-foreground">{tx.label}</p>
          <p className="text-xs text-muted-foreground">
            {tx.status === "pending" ? (
              <span className="text-gold-bright">Pending</span>
            ) : (
              new Date(tx.date).toLocaleDateString("en-IN", {
                day: "numeric",
                month: "short",
              })
            )}
          </p>
        </div>
      </div>
      <span
        className={`shrink-0 font-mono text-sm tabular-nums ${
          isCredit ? "text-emerald-400" : "text-foreground"
        }`}
      >
        {isCredit ? "+" : "−"}₹{Math.abs(tx.amount).toLocaleString("en-IN")}
      </span>
    </div>
  );
}
