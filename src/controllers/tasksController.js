const db = require("../db");

async function createTask(req, res) {
  try {
    const { user_id, title, description, is_completed } = req.body;
    // Проверим, что пользователь существует
    const u = await db.query("SELECT id FROM users WHERE id=$1", [user_id]);
    if (u.rowCount === 0)
      return res.status(400).json({ error: "User not found" });

    const result = await db.query(
      `INSERT INTO tasks (user_id, title, description, is_completed) VALUES ($1,$2,$3,$4) RETURNING *`,
      [
        user_id,
        title,
        description || null,
        is_completed === "true" || is_completed === true,
      ]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Server error" });
  }
}

async function getAllTasks(req, res) {
  // Поддержка фильтра по user_id
  const { user_id } = req.query;
  let result;
  if (user_id) {
    result = await db.query(
      "SELECT * FROM tasks WHERE user_id=$1 ORDER BY id",
      [user_id]
    );
  } else {
    result = await db.query("SELECT * FROM tasks ORDER BY id");
  }
  res.json(result.rows);
}

async function getTaskById(req, res) {
  const id = req.params.id;
  const result = await db.query("SELECT * FROM tasks WHERE id=$1", [id]);
  if (result.rowCount === 0)
    return res.status(404).json({ error: "Task not found" });
  res.json(result.rows[0]);
}

async function updateTask(req, res) {
  const id = req.params.id;
  const { title, description, is_completed, user_id } = req.body;

  // Проверка наличия
  const cur = await db.query("SELECT * FROM tasks WHERE id=$1", [id]);
  if (cur.rowCount === 0)
    return res.status(404).json({ error: "Task not found" });

  // Если меняем владельца, проверить наличие пользователя
  if (user_id) {
    const u = await db.query("SELECT id FROM users WHERE id=$1", [user_id]);
    if (u.rowCount === 0)
      return res.status(400).json({ error: "New user not found" });
  }

  const updated = await db.query(
    `UPDATE tasks SET title=$1, description=$2, is_completed=$3, user_id=$4 WHERE id=$5 RETURNING *`,
    [
      title || cur.rows[0].title,
      typeof description !== "undefined"
        ? description
        : cur.rows[0].description,
      typeof is_completed !== "undefined"
        ? is_completed === "true" || is_completed === true
        : cur.rows[0].is_completed,
      user_id || cur.rows[0].user_id,
      id,
    ]
  );
  res.json(updated.rows[0]);
}

async function deleteTask(req, res) {
  const id = req.params.id;
  const result = await db.query("DELETE FROM tasks WHERE id=$1 RETURNING *", [
    id,
  ]);
  if (result.rowCount === 0)
    return res.status(404).json({ error: "Task not found" });
  res.json({ success: true });
}

module.exports = {
  createTask,
  getAllTasks,
  getTaskById,
  updateTask,
  deleteTask,
};
