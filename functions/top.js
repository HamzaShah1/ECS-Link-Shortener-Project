export async function onRequest(context) {
  const response = await fetch(
    "https://dashboard.hamza-aws-project.com/top",
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
