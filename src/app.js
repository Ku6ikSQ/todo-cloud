// src/app.js
const express = require("express");
const cors = require("cors");
const morgan = require("morgan");
const bodyParser = require("body-parser");
const path = require("path");
const dotenv = require("dotenv");

dotenv.config();

const usersRouter = require("./routes/users");
const tasksRouter = require("./routes/tasks");
const db = require("./db");

const app = express();
const port = process.env.PORT || 3000;
const uploadDir = process.env.UPLOAD_DIR || "static";

// --- Middlewares ---
app.use(cors());
app.use(morgan("dev"));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Static files (avatars)
app.use("/static", express.static(path.join(process.cwd(), uploadDir)));

// --- Routes ---
app.use("/api/users", usersRouter);
app.use("/api/tasks", tasksRouter);

// Basic root
app.get("/", (req, res) => res.json({ status: "ok" }));

// Healthcheck: проверка доступности БД
app.get("/healthz", async (req, res) => {
  try {
    await db.query("SELECT 1");
    res.json({ status: "ok", db: "ok" });
  } catch (err) {
    res
      .status(503)
      .json({ status: "error", db: "unavailable", message: err.message });
  }
});

// 404 handler
app.use((req, res, next) => {
  res.status(404).json({ error: "Not found" });
});

// Central error handler
app.use((err, req, res, next) => {
  console.error("Unhandled error:", err);
  const status = err.status || 500;
  res.status(status).json({ error: err.message || "Internal Server Error" });
});

// --- Start server only after DB connection test ---
let server = null;

async function start() {
  try {
    // Тестовое подключение к пулу
    const client = await db.pool.connect();
    client.release();
    server = app.listen(port, () => {
      console.log(`Server listening on port ${port}`);
    });
  } catch (err) {
    console.error("Failed to connect to database. Server not started.");
    console.error(err);
    process.exit(1);
  }
}

// Graceful shutdown
async function shutdown(signal) {
  try {
    console.log(`\nReceived ${signal}. Shutting down gracefully...`);
    if (server) {
      server.close(() => {
        console.log("HTTP server closed.");
      });
    }
    // Close DB pool
    await db.pool.end();
    console.log("DB pool closed.");
    process.exit(0);
  } catch (err) {
    console.error("Error during shutdown", err);
    process.exit(1);
  }
}

process.on("SIGINT", () => shutdown("SIGINT"));
process.on("SIGTERM", () => shutdown("SIGTERM"));

// Handle unhandled rejections / exceptions
process.on("unhandledRejection", (reason) => {
  console.error("Unhandled Rejection:", reason);
});
process.on("uncaughtException", (err) => {
  console.error("Uncaught Exception:", err);
  // По желанию можно завершить процесс:
  // process.exit(1);
});

// Если запускаем как основной модуль — стартуем
if (require.main === module) {
  start();
}

// Экспорт app для тестирования
module.exports = app;
