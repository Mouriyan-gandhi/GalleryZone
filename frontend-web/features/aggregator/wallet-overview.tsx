"use client";

import { useState, type FormEvent } from "react";
import { motion } from "framer-motion";
import { toast } from "sonner";
import {
  Wallet,
  Clock3,
  Lock,
  ArrowDownRight,
  ArrowUpRight,
  Building2,
  Check,
  AlertTriangle,
} from "lucide-react";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  useAddAggregatorFundsMutation,
  useAggregatorWallet,
  useAggregatorWalletTransactions,
  useAggregatorRequestWithdrawalMutation,
} from "@/hooks/useAggregatorWallet";
import {
  useAggregatorProfile,
  useUpdateAggregatorProfileMutation,
} from "@/hooks/useAggregatorProfile";
import { GstNumberCard } from "@/components/shared/gst-number-card";
import { PaymentDismissedError } from "@/lib/razorpay-checkout";
import type { WalletTransaction } from "@/features/dashboard/dashboard-data";

const MIN_WITHDRAWAL = 1000;
// One Razorpay payment. Same bounds as the API (WALLET_TOPUP_MIN/MAX_PAISE).
const TOPUP_MIN = 1000;
const TOPUP_MAX = 500_000;

// Parallel sibling of features/dashboard/wallet-overview.tsx (Artist
// Dashboard), same layout and rules, aggregator data source.
export function WalletOverview() {
  const { data: wallet } = useAggregatorWallet();
  const { data: transactions } = useAggregatorWalletTransactions();
  const { data: profile } = useAggregatorProfile();
  const updateProfileMutation = useUpdateAggregatorProfileMutation();

  // Reserving artwork holds money here rather than charging a new payment each
  // time, so "free" — what is left after the holds — is the number that decides
  // whether the next piece can be taken.
  const balance = wallet?.balance ?? 0;
  const locked = wallet?.lockedBalance ?? 0;
  const free = balance - locked;

  const summaryCards = [
    {
      key: "free",
      label: "Free to use",
      value: free,
      hint: "Available to reserve artwork",
      icon: Wallet,
      tone: "gold" as const,
    },
    {
      key: "locked",
      label: "Held against reservations",
      value: locked,
      hint: "Advances and delivery on pieces you are displaying",
      icon: Lock,
      tone: "neutral" as const,
    },
    {
      key: "pending",
      label: "Commission pending",
      value: wallet?.pendingBalance ?? 0,
      hint: "Earned on sales, waiting to be settled",
      icon: Clock3,
      tone: "neutral" as const,
    },
  ];

  return (
    <div className="flex flex-col gap-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        {summaryCards.map((card, i) => (
          <motion.div
            key={card.key}
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.4, delay: i * 0.06, ease: "easeOut" }}
            className="rounded-lg border border-border bg-card p-5"
          >
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted-foreground">
                {card.label}
              </span>
              <card.icon
                className={`size-4 ${card.tone === "gold" ? "text-gold-bright" : "text-muted-foreground"}`}
                strokeWidth={1.75}
              />
            </div>
            <p className="mt-3 font-display text-3xl font-semibold tabular-nums text-foreground">
              ₹{card.value.toLocaleString("en-IN")}
            </p>
            <p className="mt-1 text-xs text-muted-foreground">{card.hint}</p>
          </motion.div>
        ))}
      </div>

      <AddFundsCard />

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-[1fr_1.5fr]">
        <WithdrawCard balance={free} />
        <TransactionsCard transactions={transactions ?? []} />
      </div>
      {profile && (
        <GstNumberCard
          value={profile.gstNumber ?? ""}
          onSave={(gstNumber) => updateProfileMutation.mutate({ gstNumber })}
          isPending={updateProfileMutation.isPending}
          isSuccess={updateProfileMutation.isSuccess}
          description="Used on your commission settlements and invoices. Also editable from your profile."
        />
      )}
    </div>
  );
}

// The advance and delivery are held from this balance, so an empty wallet
// means nothing can be reserved. Money comes in from the aggregator's own bank
// account, card or UPI through Razorpay.
function AddFundsCard() {
  const addFunds = useAddAggregatorFundsMutation();
  const [amount, setAmount] = useState("");
  const amountNumber = Number(amount) || 0;
  const outOfRange = amount !== "" && (!Number.isInteger(amountNumber) || amountNumber < TOPUP_MIN || amountNumber > TOPUP_MAX);

  function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (amountNumber < TOPUP_MIN || outOfRange) return;
    addFunds.mutate(amountNumber, {
      onSuccess: () => {
        toast.success("Added to your wallet", { description: `₹${amountNumber.toLocaleString("en-IN")} is ready to reserve with.` });
        setAmount("");
      },
      onError: (error) => {
        if (error instanceof PaymentDismissedError) {
          toast.info("Payment cancelled — nothing was charged.");
          return;
        }
        toast.error(error.message);
      },
    });
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="flex flex-col gap-4 rounded-lg border border-border bg-card p-5 sm:p-6"
    >
      <div className="flex items-start gap-3">
        <span className="flex size-9 shrink-0 items-center justify-center rounded-full border border-gold/30 bg-background">
          <Wallet className="size-4 text-gold-bright" strokeWidth={1.75} />
        </span>
        <div>
          <h2 className="font-display text-base font-semibold text-foreground">
            Add funds
          </h2>
          <p className="mt-0.5 text-sm leading-relaxed text-muted-foreground">
            Pay from your bank account, card or UPI through Razorpay.
            Reserving artwork holds the advance and delivery from this balance.
            The advance comes back if a piece doesn&rsquo;t sell; the delivery
            deposit comes back when it does.
          </p>
        </div>
      </div>

      <div className="flex flex-wrap items-end gap-3">
        <div className="flex flex-col gap-2">
          <Label htmlFor="topUpAmount">Amount (₹)</Label>
          <Input
            id="topUpAmount"
            type="number"
            min={TOPUP_MIN}
            max={TOPUP_MAX}
            step={1}
            placeholder="25000"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            className="h-10 w-44"
            aria-invalid={outOfRange}
            aria-describedby="topUpHint"
          />
        </div>
        <button
          type="submit"
          disabled={amountNumber < TOPUP_MIN || outOfRange || addFunds.isPending}
          className="inline-flex h-10 items-center gap-2 rounded-md border border-gold/50 px-5 text-sm font-medium text-gold-bright transition-colors hover:border-gold hover:bg-gold/10 disabled:pointer-events-none disabled:opacity-40"
        >
          {addFunds.isPending ? "Waiting for payment…" : "Add to wallet"}
        </button>
      </div>
      <p
        id="topUpHint"
        className={`text-xs ${outOfRange ? "text-destructive" : "text-muted-foreground"}`}
      >
        ₹1,000 to ₹5,00,000 in whole rupees, one payment at a time.
      </p>
    </form>
  );
}

function WithdrawCard({ balance }: { balance: number }) {
  const { data: profile } = useAggregatorProfile();
  const withdrawMutation = useAggregatorRequestWithdrawalMutation();
  const [amount, setAmount] = useState("");
  const [lastAmount, setLastAmount] = useState(0);

  const amountNumber = Number(amount) || 0;
  const belowMinimum = amount !== "" && amountNumber < MIN_WITHDRAWAL;
  const exceedsBalance = amountNumber > balance;
  const canSubmit = amountNumber >= MIN_WITHDRAWAL && amountNumber <= balance;

  function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (!canSubmit) return;
    withdrawMutation.mutate(amountNumber, {
      onSuccess: () => setLastAmount(amountNumber),
    });
  }

  if (withdrawMutation.isSuccess) {
    return (
      <motion.div
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, ease: "easeOut" }}
        className="flex flex-col items-start gap-3 rounded-lg border border-gold/30 bg-card p-6"
      >
        <span className="flex size-10 items-center justify-center rounded-full border border-gold/40 bg-gold/10">
          <Check className="size-5 text-gold-bright" />
        </span>
        <h2 className="font-display text-lg font-semibold text-foreground">
          Withdrawal requested.
        </h2>
        <p className="text-sm leading-relaxed text-muted-foreground">
          ₹{lastAmount.toLocaleString("en-IN")} will be sent to your bank
          account ending {profile?.bankAccountMasked.slice(-4)}. This
          typically takes 1–2 business days.
        </p>
        <button
          type="button"
          onClick={() => {
            withdrawMutation.reset();
            setAmount("");
          }}
          className="mt-1 text-sm font-medium text-gold-bright hover:underline"
        >
          Request another withdrawal
        </button>
      </motion.div>
    );
  }

  return (
    <div className="flex flex-col gap-5 rounded-lg border border-border bg-card p-5 sm:p-6">
      <h2 className="font-display text-base font-semibold text-foreground">
        Withdraw funds
      </h2>

      <div className="flex items-center gap-3 rounded-md border border-border p-3.5">
        <span className="flex size-9 shrink-0 items-center justify-center rounded-full border border-gold/30 bg-background">
          <Building2 className="size-4 text-gold-bright" strokeWidth={1.5} />
        </span>
        <div className="min-w-0">
          <p className="truncate text-sm font-medium text-foreground">
            {profile?.bankAccountMasked}
          </p>
          <p className="text-xs text-muted-foreground">{profile?.ifsc}</p>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="flex flex-col gap-2">
        <Label htmlFor="withdrawAmount">Amount (₹)</Label>
        <Input
          id="withdrawAmount"
          type="number"
          min={MIN_WITHDRAWAL}
          step={1}
          placeholder="5000"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          className="h-10"
          aria-invalid={belowMinimum || exceedsBalance}
        />

        {belowMinimum ? (
          <p className="flex items-center gap-1.5 text-xs text-destructive">
            <AlertTriangle className="size-3" />
            Minimum withdrawal is ₹1,000
          </p>
        ) : exceedsBalance ? (
          <p className="flex items-center gap-1.5 text-xs text-destructive">
            <AlertTriangle className="size-3" />
            Exceeds your available balance
          </p>
        ) : (
          <p className="text-xs text-muted-foreground">
            Minimum ₹1,000 · Available ₹{balance.toLocaleString("en-IN")}
          </p>
        )}

        <button
          type="submit"
          disabled={!canSubmit || withdrawMutation.isPending}
          className="mt-2 inline-flex items-center justify-center gap-2 rounded-md bg-gradient-to-b from-gold-bright to-gold px-5 py-2.5 text-sm font-semibold text-[#171310] transition-transform hover:scale-[1.02] disabled:pointer-events-none disabled:opacity-40"
        >
          Request withdrawal
        </button>
      </form>
    </div>
  );
}

function TransactionsCard({
  transactions,
}: {
  transactions: WalletTransaction[];
}) {
  return (
    <div className="rounded-lg border border-border bg-card p-5 sm:p-6">
      <h2 className="font-display text-base font-semibold text-foreground">
        Transaction history
      </h2>

      <div
        className={`mt-3 flex flex-col ${
          transactions.length > 5 ? "max-h-[320px] overflow-y-auto pr-1" : ""
        }`}
      >
        {transactions.length === 0 ? (
          <p className="py-6 text-center text-sm text-muted-foreground">
            No transactions yet.
          </p>
        ) : (
          transactions.map((tx) => <TransactionRow key={tx.id} tx={tx} />)
        )}
      </div>
    </div>
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
