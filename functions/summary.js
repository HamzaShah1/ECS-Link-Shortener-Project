export async function onRequest(context) {
  const response = await fetch(
    "https://dashboard.hamza-aws-project.com/summary",
    {
      method: context.request.method,
      headers: {
        "User-Agent": "Mozilla/5.0",
        "Accept": "application/json",
      },
    }
  );

  return new Response(response.body, {
    status: response.status,
    headers: {
      "Content-Type": response.headers.get("Content-Type") || "application/json",
      "Cache-Control": "no-store",
    },
  });
}
