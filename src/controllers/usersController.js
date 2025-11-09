const db = require("../db");

async function createUser(req, res) {
  try {
    const { name, login, email } = req.body;
    const avatar = req.file ? req.file.filename : null;
    const result = await db.query(
      `INSERT INTO users (name, login, email, avatar) VALUES ($1,$2,$3,$4) RETURNING *`,
      [name, login, email, avatar]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    if (err.code === "23505") {
      return res.status(409).json({ error: "Login or email already exists" });
    }
    console.error(err);
    res.status(500).json({ error: "Server error" });
  }
}

async function getAllUsers(req, res) {
  const result = await db.query("SELECT * FROM users ORDER BY id");
  res.json(result.rows);
}

async function getUserById(req, res) {
  const id = req.params.id;
  const result = await db.query("SELECT * FROM users WHERE id=$1", [id]);
  if (result.rowCount === 0)
    return res.status(404).json({ error: "User not found" });
  res.json(result.rows[0]);
}

async function updateUser(req, res) {
  const id = req.params.id;
  const { name, login, email } = req.body;
  const avatar = req.file ? req.file.filename : null;

  try {
    // Получим текущего пользователя
    const cur = await db.query("SELECT * FROM users WHERE id=$1", [id]);
    if (cur.rowCount === 0)
      return res.status(404).json({ error: "User not found" });

    const newAvatar = avatar || cur.rows[0].avatar;

    const result = await db.query(
      `UPDATE users SET name=$1, login=$2, email=$3, avatar=$4 WHERE id=$5 RETURNING *`,
      [
        name || cur.rows[0].name,
        login || cur.rows[0].login,
        email || cur.rows[0].email,
        newAvatar,
        id,
      ]
    );
    res.json(result.rows[0]);
  } catch (err) {
    if (err.code === "23505")
      return res.status(409).json({ error: "Login or email already exists" });
    console.error(err);
    res.status(500).json({ error: "Server error" });
  }
}

async function deleteUser(req, res) {
  const id = req.params.id;
  const result = await db.query("DELETE FROM users WHERE id=$1 RETURNING *", [
    id,
  ]);
  if (result.rowCount === 0)
    return res.status(404).json({ error: "User not found" });
  res.json({ success: true });
}

module.exports = {
  createUser,
  getAllUsers,
  getUserById,
  updateUser,
  deleteUser,
};
