const express = require("express");
const router = express.Router();
const ctrl = require("../controllers/tasksController");
const { validateTaskPayload } = require("../validators");

router.post("/", async (req, res) => {
  if (!validateTaskPayload(req.body))
    return res.status(400).json({ error: "Missing title" });
  return ctrl.createTask(req, res);
});

router.get("/", ctrl.getAllTasks);
router.get("/:id", ctrl.getTaskById);
router.put("/:id", ctrl.updateTask);
router.delete("/:id", ctrl.deleteTask);

module.exports = router;
