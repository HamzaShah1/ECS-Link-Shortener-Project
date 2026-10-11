export async function onRequest() {
  return Response.json({
    diagnostic: "pages-function-running",
    status: "ok"
  });
}
