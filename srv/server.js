const cds = require("@sap/cds");

cds.on("bootstrap", (app) => {
  if (process.env.NODE_ENV === "production") return;

  app.use((req, res, next) => {
    if (req.query._user === "logout") {
      res.setHeader("Set-Cookie", "_dev_user=; Path=/; Max-Age=0");
      return res.redirect(req.path);
    }

    let userId = req.query._user;

    if (!userId && req.headers.cookie) {
      const match = req.headers.cookie.match(/_dev_user=([^;]+)/);
      if (match) userId = decodeURIComponent(match[1]);
    }

    if (userId) {
      const creds = Buffer.from(`${userId}:`).toString("base64");
      req.headers.authorization = `Basic ${creds}`;

      // Persist as cookie so the SPA's subsequent OData calls (no query param) are still recognized.
      if (req.query._user) {
        res.setHeader(
          "Set-Cookie",
          `_dev_user=${encodeURIComponent(userId)}; Path=/; SameSite=Lax`,
        );
      }
    }

    next();
  });
});

module.exports = cds.server;
