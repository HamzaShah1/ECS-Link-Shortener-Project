export async function onRequest() {
  const response = await fetch(
    "https://dashboard.hamza-aws-project.com/summary",
    {
      headers: {
        "User-Agent": "Mozilla/5.0",
        "Accept": "application/json",
      },
    }
  );

  return Response.json({
    upstreamStatus: response.status,
    upstreamBody: await response.text(),
  });
}
