function validateUserPayload(body) {
  const { name, login, email } = body;
  if (!name || !login || !email) return false;
  return true;
}

function validateTaskPayload(body) {
  const { title } = body;
  if (!title) return false;
  return true;
}

module.exports = { validateUserPayload, validateTaskPayload };
