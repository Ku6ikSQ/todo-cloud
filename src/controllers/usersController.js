const db = require("../db")
const storage = require("../services/storage")
const path = require("path")

async function createUser(req, res) {
  try {
    const { name, login, email } = req.body
    let avatar = null

    if (req.file) {
      const fileExtension = path.extname(req.file.originalname)
      const fileName = `avatars/${Date.now()}_${
        login || "user"
      }${fileExtension}`

      try {
        avatar = await storage.uploadFile(
          fileName,
          req.file.buffer,
          req.file.mimetype
        )
      } catch (error) {
        console.error("Error uploading file to Object Storage:", error)
        return res.status(500).json({ error: "Failed to upload file" })
      }
    }

    const result = await db.query(
      `INSERT INTO users (name, login, email, avatar) VALUES ($1,$2,$3,$4) RETURNING *`,
      [name, login, email, avatar]
    )
    res.status(201).json(result.rows[0])
  } catch (err) {
    if (err.code === "23505") {
      return res.status(409).json({ error: "Login or email already exists" })
    }
    console.error(err)
    res.status(500).json({ error: "Server error" })
  }
}

async function getAllUsers(req, res) {
  const result = await db.query("SELECT * FROM users ORDER BY id")
  res.json(result.rows)
}

async function getUserById(req, res) {
  const id = req.params.id
  const result = await db.query("SELECT * FROM users WHERE id=$1", [id])
  if (result.rowCount === 0)
    return res.status(404).json({ error: "User not found" })
  res.json(result.rows[0])
}

async function updateUser(req, res) {
  const id = req.params.id
  const { name, login, email } = req.body

  try {
    // Получим текущего пользователя
    const cur = await db.query("SELECT * FROM users WHERE id=$1", [id])
    if (cur.rowCount === 0)
      return res.status(404).json({ error: "User not found" })

    let newAvatar = cur.rows[0].avatar

    if (req.file) {
      // Удаляем старый аватар, если есть
      if (cur.rows[0].avatar) {
        try {
          // Извлекаем ключ из URL (последняя часть после последнего /)
          const oldKey = cur.rows[0].avatar.split("/").pop()
          await storage.deleteFile(`avatars/${oldKey}`)
        } catch (error) {
          console.error("Error deleting old avatar:", error)
          // Продолжаем выполнение даже если удаление не удалось
        }
      }

      // Загружаем новый аватар
      const fileExtension = path.extname(req.file.originalname)
      const fileName = `avatars/${Date.now()}_${
        login || cur.rows[0].login || "user"
      }${fileExtension}`

      try {
        newAvatar = await storage.uploadFile(
          fileName,
          req.file.buffer,
          req.file.mimetype
        )
      } catch (error) {
        console.error("Error uploading file to Object Storage:", error)
        return res.status(500).json({ error: "Failed to upload file" })
      }
    }

    const result = await db.query(
      `UPDATE users SET name=$1, login=$2, email=$3, avatar=$4 WHERE id=$5 RETURNING *`,
      [
        name || cur.rows[0].name,
        login || cur.rows[0].login,
        email || cur.rows[0].email,
        newAvatar,
        id,
      ]
    )
    res.json(result.rows[0])
  } catch (err) {
    if (err.code === "23505")
      return res.status(409).json({ error: "Login or email already exists" })
    console.error(err)
    res.status(500).json({ error: "Server error" })
  }
}

async function deleteUser(req, res) {
  const id = req.params.id

  try {
    // Получаем пользователя перед удалением, чтобы удалить аватар
    const user = await db.query("SELECT avatar FROM users WHERE id=$1", [id])

    if (user.rowCount === 0)
      return res.status(404).json({ error: "User not found" })

    // Удаляем аватар из Object Storage, если он есть
    if (user.rows[0].avatar) {
      try {
        const avatarKey = user.rows[0].avatar.split("/").pop()
        await storage.deleteFile(`avatars/${avatarKey}`)
      } catch (error) {
        console.error("Error deleting avatar from Object Storage:", error)
        // Продолжаем удаление пользователя даже если файл не удалось удалить
      }
    }

    // Удаляем пользователя из БД
    const result = await db.query("DELETE FROM users WHERE id=$1 RETURNING *", [
      id,
    ])
    res.json({ success: true })
  } catch (err) {
    console.error(err)
    res.status(500).json({ error: "Server error" })
  }
}

module.exports = {
  createUser,
  getAllUsers,
  getUserById,
  updateUser,
  deleteUser,
}
