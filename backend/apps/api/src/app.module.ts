import { MiddlewareConsumer, Module, NestModule } from "@nestjs/common";
import { APP_GUARD } from "@nestjs/core";
import { ThrottlerGuard, ThrottlerModule } from "@nestjs/throttler";
import { HealthController } from "./health.controller.ts";
import { AuthController } from "./auth/auth.controller.ts";
import { PublicPricingRulesController, RateConfigController } from "./rate-config.controller.ts";
import { ArtworksController } from "./artworks.controller.ts";
import { OrdersController } from "./orders.controller.ts";
import { AggregatorController } from "./aggregator.controller.ts";
import { ModerationController } from "./moderation.controller.ts";
import { ArtistArtworksController } from "./artist-artworks.controller.ts";
import { WithdrawalsController, AdminWithdrawalsController } from "./withdrawals.controller.ts";
import { ArtistWalletController, AggregatorWalletController, CustomerWalletController } from "./wallets.controller.ts";
import { AdminController } from "./admin.controller.ts";
import { PublicArtistsController, PublicStatsController } from "./public-profiles.controller.ts";
import { AdminArtworksController } from "./admin-artworks.controller.ts";
import { AddressesController } from "./addresses.controller.ts";
import { AdminSettlementsController } from "./admin-settlements.controller.ts";
import { AggregatorSalesController } from "./aggregator-sales.controller.ts";
import { DeactivationController } from "./deactivation.controller.ts";
import { OrderListingsController } from "./order-listings.controller.ts";
import { AdminOrdersController } from "./admin-orders.controller.ts";
import { GallerySpacesController } from "./gallery-spaces.controller.ts";
import { MessagingController } from "./messaging.controller.ts";
import { ResaleController } from "./resale.controller.ts";
import { ReportsController } from "./reports.controller.ts";
import { CoaController } from "./coa.controller.ts";
import { VerifyController } from "./verify.controller.ts";
import { PassportController } from "./passport.controller.ts";
import { OwnershipController } from "./ownership.controller.ts";
import { MouController } from "./mou.controller.ts";
import { ImagesController } from "./images.controller.ts";
import { Storage } from "./storage.ts";
import { ListingBackfill } from "./listing-backfill.ts";
import { HoldingExpirySweep } from "./holding-expiry.ts";
import { Mailer } from "./mail/mailer.ts";
import { Emails } from "./mail/emails.ts";
import { PaymentsController } from "./payments/payments.controller.ts";
import { ProfileController } from "./profile.controller.ts";
import { CollectionController } from "./collection.controller.ts";
import { Razorpay } from "./payments/razorpay.ts";
import { RolesGuard } from "./auth/roles.guard.ts";
import { requestIdMiddleware } from "./request-id.middleware.ts";
import { DbModule } from "./db.module.ts";

@Module({
  imports: [
    DbModule,
    // Per-IP token buckets, in memory (one instance today). "burst" stops
    // scripted hammering of the public routes; "sustained" caps a single
    // client at a rate a human never reaches. Auth-gated routes get the
    // same limits — a stolen token shouldn't scrape the API either.
    ThrottlerModule.forRoot([
      { name: "burst", ttl: 1_000, limit: 20 },
      { name: "sustained", ttl: 60_000, limit: 300 },
    ]),
  ],
  controllers: [
    HealthController,
    AuthController,
    RateConfigController,
    PublicPricingRulesController,
    ArtworksController,
    OrdersController,
    AggregatorController,
    ModerationController,
    ArtistArtworksController,
    WithdrawalsController,
    AdminWithdrawalsController,
    ArtistWalletController,
    AggregatorWalletController,
    CustomerWalletController,
    AdminController,
    PublicArtistsController,
    PublicStatsController,
    AdminArtworksController,
    AddressesController,
    AdminSettlementsController,
    AggregatorSalesController,
    DeactivationController,
    OrderListingsController,
    AdminOrdersController,
    GallerySpacesController,
    MessagingController,
    ResaleController,
    ReportsController,
    CoaController,
    VerifyController,
    PassportController,
    OwnershipController,
    MouController,
    ImagesController,
    PaymentsController,
    ProfileController,
    CollectionController,
  ],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
    Storage,
    ListingBackfill,
    HoldingExpirySweep,
    Mailer,
    Emails,
    Razorpay,
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(requestIdMiddleware).forRoutes("*");
  }
}
