export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === "/health") {
      return Response.json({
        status: "ok",
        service: "XRINet API"
      });
    }

    if (url.pathname === "/db-check") {
      try {
        const result = await env.DB
          .prepare("SELECT 1 AS connected")
          .first();

        return Response.json({
          status: "ok",
          database: "connected",
          result
        });
      } catch (error) {
        return Response.json({
          status: "error",
          database: "disconnected"
        }, { status: 500 });
      }
    }

    return Response.json({
      error: "Not Found"
    }, { status: 404 });
  }
};
