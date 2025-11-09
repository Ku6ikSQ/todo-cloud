const express = require("express");
const router = express.Router();
const upload = require("../middlewares/upload");
const ctrl = require("../controllers/usersController");
const { validateUserPayload } = require("../validators");

// Создать пользователя (с опциональной загрузкой аватара)
router.post("/", upload.single("avatar"), async (req, res) => {
  if (!validateUserPayload(req.body))
    return res.status(400).json({ error: "Missing fields" });
  return ctrl.createUser(req, res);
});

router.get("/", ctrl.getAllUsers);
router.get("/:id", ctrl.getUserById);
router.put("/:id", upload.single("avatar"), ctrl.updateUser);
router.delete("/:id", ctrl.deleteUser);

module.exports = router;
