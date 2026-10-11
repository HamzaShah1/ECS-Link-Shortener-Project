
const API_ORIGIN = "https://hamza-aws-project.com";
const DASHBOARD_ORIGIN = "https://dashboard.hamza-aws-project.com";

export async function onRequest(context) {
  const { request, params } = context;
  const url = new URL(request.url);
  const path = Array.isArray(params.path)
    ? params.path.join("/")
    : params.path || "";

  // Let Cloudflare Pages serve the frontend and its static assets.
  if (
    path === "" ||
    path === "index.html" ||
    path.startsWith("assets/") ||
    path.endsWith(".css") ||
    path.endsWith(".js") ||
    path.endsWith(".ico") ||
    path.endsWith(".png") ||
    path.endsWith(".svg")
  ) {
    return new Response("Not found", { status: 404 });
  }

  let upstream;

  if (path === "shorten" && request.method === "POST") {
    upstream = API_ORIGIN;
  } else if (
    ["summary", "top", "recent"].includes(path) ||
    path.startsWith("url/")
  ) {
    upstream = DASHBOARD_ORIGIN;
  } else {
    return new Response("Not found", { status: 404 });
  }

  const response = await fetch(`${upstream}/${path}`, {
    method: request.method,
    headers: request.headers,
    body: ["GET", "HEAD"].includes(request.method)
      ? undefined
      : request.body,
  });

  return new Response(response.body, {
    status: response.status,
    headers: {
      "Content-Type":
        response.headers.get("Content-Type") || "application/json",
      "Cache-Control": "no-store",
    },
  });
}
