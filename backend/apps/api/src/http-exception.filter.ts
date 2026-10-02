// Global exception filter — every error response leaving this API is RFC
// 7807 Problem Details + a machine-readable `code` field (plan.md §18,
// the same shape ZodValidationPipe already produces for validation
// errors). Without this filter, an unhandled exception would fall through
// to Nest's default error shape, which doesn't match that contract —
// meaning error-format consistency was previously true only for validation
// errors, by accident of which code path happened to run first.

import * as Sentry from "@sentry/node";
import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from "@nestjs/common";
import type { Response } from "express";
import { DbError, NfcError } from "@galleryzone/db";
import { IllegalTransitionError } from "@galleryzone/domain";

interface ProblemDetails {
  type: string;
  title: string;
  status: number;
  code: string;
  detail?: string;
  [key: string]: unknown;
}

function codeFor(status: number): string {
  switch (status) {
    case 400:
      return "bad_request";
    case 401:
      return "unauthorized";
    case 403:
      return "forbidden";
    case 404:
      return "not_found";
    case 409:
      return "conflict";
    case 429:
      return "rate_limited";
    case 501:
      return "not_implemented";
    default:
      return status >= 500 ? "internal_error" : "error";
  }
}

/**
 * A deliberate refusal from the db or domain layer, mapped to a real status
 * so it doesn't fall through as a 500.
 *
 * Controllers that want a specific `code`, or a status other than these two,
 * still catch the error themselves — this is the floor. It exists because
 * ten error classes had no controller catching them at all, so genuine
 * answers ("that is below the minimum withdrawal", "this sale was already
 * marked remitted") reached the caller as "Internal server error".
 *
 * The "No " prefix convention is documented on DbError.
 */
function domainProblem(exception: unknown): ProblemDetails | null {
  if (exception instanceof IllegalTransitionError) {
    return { type: "about:blank", title: exception.message, status: HttpStatus.CONFLICT, code: "illegal_transition" };
  }
  // NFC refusals carry their own status and the `code` the apps switch on
  // (nfc_already_locked, tag_already_bound, nfc_lock_required, ...).
  if (exception instanceof NfcError) {
    if (exception.status === HttpStatus.NOT_FOUND) return { type: "about:blank", title: "Not found", status: HttpStatus.NOT_FOUND, code: "not_found" };
    return { type: "about:blank", title: exception.message, status: exception.status, code: exception.code };
  }
  if (!(exception instanceof DbError)) return null;
  if (exception.message.startsWith("No ")) {
    // Generic title: most of these are scoped to a caller, and echoing the
    // message back would confirm whether the id exists.
    return { type: "about:blank", title: "Not found", status: HttpStatus.NOT_FOUND, code: "not_found" };
  }
  return { type: "about:blank", title: exception.message, status: HttpStatus.CONFLICT, code: "conflict" };
}

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();

    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const body = exception.getResponse();
      // ZodValidationPipe (and anything else) that already threw a
      // Problem-Details-shaped body is passed through as-is, so we don't
      // double-wrap or lose its `issues` array.
      if (typeof body === "object" && body !== null && "code" in body) {
        response.status(status).json(body);
        return;
      }
      const problem: ProblemDetails = {
        type: "about:blank",
        title: typeof body === "string" ? body : exception.message,
        status,
        code: codeFor(status),
      };
      response.status(status).json(problem);
      return;
    }

    const known = domainProblem(exception);
    if (known) {
      response.status(known.status).json(known);
      return;
    }

    // Anything that wasn't deliberately thrown as an HttpException is a
    // bug, not a client error — never leak its message to the caller,
    // but DO log it server-side or the 500 is undebuggable.
    const req = ctx.getRequest<{ method?: string; originalUrl?: string }>();
    this.logger.error(`${req.method ?? "?"} ${req.originalUrl ?? "?"} -> unhandled`, exception instanceof Error ? exception.stack : String(exception));
    Sentry.captureException(exception, { extra: { method: req.method, url: req.originalUrl } });
    const problem: ProblemDetails = {
      type: "about:blank",
      title: "Internal server error",
      status: HttpStatus.INTERNAL_SERVER_ERROR,
      code: "internal_error",
    };
    response.status(HttpStatus.INTERNAL_SERVER_ERROR).json(problem);
  }
}
