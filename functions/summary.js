export async function onRequest() {
  const response = await fetch(
    "https://dashboard.hamza-aws-project.com/summary"
  );

  const body = await response.text();

  return Response.json({
    upstreamStatus: response.status,
    upstreamBody: body,
  });
}
