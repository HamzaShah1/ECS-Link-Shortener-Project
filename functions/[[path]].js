
const API_ORIGIN = "https://hamza-aws-project.com";
const DASHBOARD_ORIGIN = "https://dashboard.hamza-aws-project.com";

export async function onRequest(context) {
  const { request, params } = context;
  const path = Array.isArray(params.path)
    ? params.path.join("/")
    : params.path || "";

  let upstream;

  if (path === "shorten" && request.method === "POST") {
    upstream = API_ORIGIN;
  } else if (["summary", "top", "recent"].includes(path) || path.startsWith("url/")) {
    upstream = DASHBOARD_ORIGIN;
  } else {
    return new Response("Not found", { status: 404 });
  }

  const target = `${upstream}/${path}`;
  const response = await fetch(target, {
    method: request.method,
    headers: request.headers,
    body: request.method === "GET" || request.method === "HEAD"
      ? undefined
      : request.body,
  });

  return new Response(response.body, {
    status: response.status,
    headers: {
      "Content-Type": response.headers.get("Content-Type") || "application/json",
      "Cache-Control": "no-store",
    },
  });
}
