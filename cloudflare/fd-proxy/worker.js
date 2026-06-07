// fd-proxy — a tiny Cloudflare Worker that lets our IPv6-only server reach the
// IPv4-only football-data.org API. Cloudflare's edge is dual-stack: the app
// calls this Worker over IPv6, the Worker reaches football-data over IPv4.
//
// Gated by a shared secret: requests must send `X-Proxy-Key` matching the
// PROXY_KEY secret. The real football-data token (FOOTBALL_DATA_TOKEN secret)
// is attached here and never leaves Cloudflare.
//
// Secrets to configure (Workers > Settings > Variables, "Encrypt"):
//   FOOTBALL_DATA_TOKEN  – your football-data.org API token
//   PROXY_KEY            – shared secret the app sends as X-Proxy-Key

const UPSTREAM = "https://api.football-data.org";

export default {
  async fetch(request, env) {
    if (request.headers.get("X-Proxy-Key") !== env.PROXY_KEY) {
      return new Response("forbidden", { status: 403 });
    }

    const { pathname, search } = new URL(request.url);
    const upstream = await fetch(UPSTREAM + pathname + search, {
      method: "GET",
      headers: { "X-Auth-Token": env.FOOTBALL_DATA_TOKEN, Accept: "application/json" },
    });

    return new Response(upstream.body, {
      status: upstream.status,
      headers: { "Content-Type": upstream.headers.get("Content-Type") || "application/json" },
    });
  },
};
