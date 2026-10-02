import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";
import { ArrowRight, Check } from "lucide-react";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";
import { PassportHeroCta } from "@/features/passport/passport-hero-cta";
import { PassportViewerPanel } from "@/features/passport/passport-viewer-panel";
import {
  PASSPORT_TOPICS,
  getPassportTopic,
  type PassportTopicSlug,
} from "@/features/passport/passport-topics";
import { cn } from "@/lib/utils";

// Only the four topics exist; anything else is a real 404.
export const dynamicParams = false;

export function generateStaticParams() {
  return PASSPORT_TOPICS.map((topic) => ({ topic: topic.slug }));
}

type PageParams = { params: Promise<{ topic: string }> };

export async function generateMetadata({ params }: PageParams): Promise<Metadata> {
  const topic = getPassportTopic((await params).topic);
  if (!topic) return {};
  return { title: `${topic.title} | GalleryZone`, description: topic.seoDescription };
}

export default async function PassportTopicPage({ params }: PageParams) {
  const topic = getPassportTopic((await params).topic);
  if (!topic) notFound();

  const index = PASSPORT_TOPICS.findIndex((t) => t.slug === topic.slug);
  const next = PASSPORT_TOPICS[index + 1];

  return (
    <>
      <SiteHeader />
      <main className="flex flex-1 flex-col">
        <section className="border-b border-border/60">
          <div className="mx-auto grid max-w-[1200px] grid-cols-1 gap-10 px-6 py-10 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.05fr)] lg:items-center lg:gap-16 lg:px-10 lg:py-16">
            <div className="flex flex-col">
              <TopicNav current={topic.slug} />
              <h1 className="mt-8 font-display text-4xl leading-[1.1] font-semibold tracking-tight text-balance text-foreground sm:text-5xl">
                {topic.headline}
              </h1>
              <p className="mt-4 max-w-md text-base leading-relaxed text-pretty text-muted-foreground">
                {topic.lede}
              </p>
              <PassportHeroCta />
            </div>

            <div className="relative aspect-[16/11] overflow-hidden rounded-xl bg-muted shadow-[0_30px_60px_-30px_rgb(0_0_0/0.6)] ring-1 ring-border">
              <Image
                src={topic.image}
                alt={topic.imageAlt}
                fill
                priority
                sizes="(min-width: 1024px) 560px, 100vw"
                className="object-cover"
                style={{ objectPosition: topic.imagePosition }}
              />
            </div>
          </div>
        </section>

        <section
          aria-labelledby="includes"
          className="mx-auto w-full max-w-[1200px] px-6 py-14 lg:px-10 lg:py-20"
        >
          <div className="grid grid-cols-1 gap-8 lg:grid-cols-[minmax(0,0.8fr)_minmax(0,1.2fr)] lg:gap-16">
            <h2
              id="includes"
              className="font-display text-2xl font-semibold text-foreground sm:text-3xl"
            >
              {topic.includesHeading}
            </h2>
            <div>
              <ul className="flex flex-col divide-y divide-border">
                {topic.includes.map((item) => (
                  <li key={item.title} className="flex gap-4 py-5 first:pt-0">
                    <span
                      aria-hidden="true"
                      className="mt-0.5 flex size-6 shrink-0 items-center justify-center rounded-full border border-gold/50 text-gold-bright"
                    >
                      <Check className="size-3.5" strokeWidth={2.25} />
                    </span>
                    <div>
                      <h3 className="font-medium text-foreground">{item.title}</h3>
                      <p className="mt-1 text-sm leading-relaxed text-muted-foreground">
                        {item.body}
                      </p>
                    </div>
                  </li>
                ))}
              </ul>
              {topic.note && (
                <p className="mt-6 max-w-lg text-sm leading-relaxed text-muted-foreground">
                  {topic.note}
                </p>
              )}
            </div>
          </div>
        </section>

        <PassportViewerPanel topic={topic.slug} />

        <section
          aria-labelledby="steps"
          className="mx-auto w-full max-w-[1200px] px-6 py-14 lg:px-10 lg:py-20"
        >
          <h2 id="steps" className="font-display text-2xl font-semibold text-foreground sm:text-3xl">
            {topic.stepsHeading}
          </h2>
          <ol className="mt-10 grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-4">
            {topic.steps.map((step, i) => (
              <li key={step.title}>
                <span className="flex size-9 items-center justify-center rounded-full border border-gold/50 text-sm font-semibold text-gold-bright tabular-nums">
                  {i + 1}
                </span>
                <h3 className="mt-4 font-medium text-foreground">{step.title}</h3>
                <p className="mt-1.5 text-sm leading-relaxed text-muted-foreground">{step.body}</p>
              </li>
            ))}
          </ol>
        </section>

        <div className="mx-auto w-full max-w-[1200px] px-6 pb-16 lg:px-10 lg:pb-24">
          <Link
            href={next ? `/passport/${next.slug}` : "/marketplace"}
            className="group flex items-center justify-between gap-6 rounded-2xl border border-border bg-card/40 p-6 transition-colors duration-200 hover:border-gold/50 focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 sm:p-8"
          >
            <div>
              <p className="text-sm text-muted-foreground">{next ? "Next" : "Ready to look?"}</p>
              <p className="mt-1 font-display text-2xl font-semibold text-foreground">
                {next ? next.title : "Browse the marketplace"}
              </p>
              <p className="mt-1 max-w-md text-sm text-muted-foreground">
                {next ? next.summary : "Every piece there has a passport."}
              </p>
            </div>
            <ArrowRight
              className="size-6 shrink-0 text-gold-bright transition-transform duration-200 group-hover:translate-x-1"
              strokeWidth={1.75}
            />
          </Link>
        </div>
      </main>
      <SiteFooter />
    </>
  );
}

// The four topics as one set: moving between them never goes back through
// the landing page.
function TopicNav({ current }: { current: PassportTopicSlug }) {
  return (
    <nav
      aria-label="Passport topics"
      className="-mx-6 flex gap-2 overflow-x-auto px-6 pb-1 [scrollbar-width:none] sm:mx-0 sm:px-0"
    >
      {PASSPORT_TOPICS.map((topic) => {
        const active = topic.slug === current;
        return (
          <Link
            key={topic.slug}
            href={`/passport/${topic.slug}`}
            aria-current={active ? "page" : undefined}
            className={cn(
              "inline-flex h-10 shrink-0 items-center gap-2 rounded-full border px-4 text-sm font-medium transition-[background-color,border-color,color,transform] duration-150 ease-out focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/50 active:scale-[0.97]",
              active
                ? "border-transparent bg-gold text-[#171310] dark:bg-gold-bright"
                : "border-border text-foreground/80 hover:border-gold/50 hover:text-foreground",
            )}
          >
            <topic.icon className="size-4" strokeWidth={1.75} />
            {topic.title}
          </Link>
        );
      })}
    </nav>
  );
}
