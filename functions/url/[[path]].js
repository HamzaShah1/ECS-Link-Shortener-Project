export async function onRequest(context) {
  const path = Array.isArray(context.params.path)
    ? context.params.path.join("/")
    : context.params.path || "";

  const response = await fetch(
    `https://dashboard.hamza-aws-project.com/url/${path}`,
    { method: context.request.method }
  );

  return new Response(response.body, {
    status: response.status,
    headers: {
      "Content-Type": response.headers.get("Content-Type") || "application/json",
      "Cache-Control": "no-store",
    },
  });
}
