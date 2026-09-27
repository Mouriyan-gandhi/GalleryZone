const API_BASE = "http://localhost:8080";
const AUTH_BASE = "http://127.0.0.1:9099";
const REQUEST_TIMEOUT_MS = 20_000;

export interface DemoAccount {
  uid: string;
  email: string;
  token: string;
}

function describe(value: unknown): string {
  if (typeof value === "string") return value;
  try {
    return JSON.stringify(value);
  } catch {
    return String(value);
  }
}

async function responseBody(response: Response): Promise<unknown> {
  const text = await response.text();
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

export async function request<T>(
  path: string,
  options: { method?: string; token?: string; body?: unknown; headers?: Record<string, string> } = {},
): Promise<T> {
  const headers = new Headers(options.headers);
  if (options.token) headers.set("Authorization", `Bearer ${options.token}`);
  let body: BodyInit | undefined;
  if (options.body instanceof Uint8Array) {
    body = options.body;
  } else if (options.body !== undefined) {
    headers.set("Content-Type", "application/json");
    body = JSON.stringify(options.body);
  }
  let response: Response;
  try {
    response = await fetch(`${API_BASE}${path}`, {
      method: options.method ?? (body === undefined ? "GET" : "POST"),
      headers,
      body,
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
    });
  } catch (error) {
    throw new Error(`API did not respond for ${options.method ?? "GET"} ${path}: ${String(error)}. The seed will not restart it.`);
  }
  const parsed = await responseBody(response);
  if (!response.ok) throw new Error(`${options.method ?? "GET"} ${path} -> ${response.status}: ${describe(parsed)}`);
  return parsed as T;
}

export async function resetEmulators(projectId: string): Promise<void> {
  const firestoreUrl = `http://127.0.0.1:8085/emulator/v1/projects/${encodeURIComponent(projectId)}/databases/(default)/documents`;
  const authUrl = `http://127.0.0.1:9099/emulator/v1/projects/${encodeURIComponent(projectId)}/accounts`;
  for (const url of [firestoreUrl, authUrl]) {
    const response = await fetch(url, { method: "DELETE", signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS) });
    if (!response.ok) throw new Error(`Emulator reset failed for ${url}: ${response.status} ${await response.text()}`);
  }
}

export async function register(input: { email: string; password: string; name: string; role: string }): Promise<string> {
  const result = await request<{ uid: string }>("/v1/auth/register", { method: "POST", body: input });
  return result.uid;
}

export async function signIn(email: string, password: string): Promise<string> {
  const response = await fetch(
    `${AUTH_BASE}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo-api-key`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
    },
  );
  const body = (await response.json()) as { idToken?: string; error?: unknown };
  if (!response.ok || !body.idToken) throw new Error(`Auth emulator sign-in failed for ${email}: ${response.status} ${describe(body)}`);
  return body.idToken;
}

export async function healthCheck(): Promise<void> {
  const health = await request<{ status: string; emulator?: boolean }>("/v1/health");
  if (health.status !== "ok") throw new Error(`API health check returned ${describe(health)}`);
  // An API without this flag (older build, or anything real) is refused: the
  // first seed write registers an account and would hit a real project.
  if (health.emulator !== true) {
    throw new Error("The API on this URL is not running against the Firebase emulators (run `npm run demo:api`). Refusing to seed.");
  }
}
