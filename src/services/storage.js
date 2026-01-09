const {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
  GetObjectCommand,
} = require("@aws-sdk/client-s3")
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner")

const s3Client = new S3Client({
  endpoint:
    process.env.YANDEX_OBJECT_STORAGE_ENDPOINT ||
    "https://storage.yandexcloud.net",
  region: "ru-central1",
  credentials: {
    accessKeyId: process.env.YANDEX_ACCESS_KEY_ID,
    secretAccessKey: process.env.YANDEX_SECRET_ACCESS_KEY,
  },
})

const BUCKET_NAME = process.env.YANDEX_OBJECT_STORAGE_BUCKET

/**
 * Загрузка файла в Object Storage
 * @param {string} key - путь к файлу в bucket
 * @param {Buffer} buffer - содержимое файла
 * @param {string} contentType - MIME тип файла
 * @returns {Promise<string>} URL файла
 */
async function uploadFile(key, buffer, contentType) {
  const command = new PutObjectCommand({
    Bucket: BUCKET_NAME,
    Key: key,
    Body: buffer,
    ContentType: contentType,
  })

  await s3Client.send(command)

  // Возвращаем публичный URL (если bucket публичный)
  // Или используем presigned URL для временного доступа
  return `https://${BUCKET_NAME}.storage.yandexcloud.net/${key}`
}

/**
 * Удаление файла из Object Storage
 * @param {string} key - путь к файлу в bucket
 */
async function deleteFile(key) {
  const command = new DeleteObjectCommand({
    Bucket: BUCKET_NAME,
    Key: key,
  })

  await s3Client.send(command)
}

/**
 * Получение presigned URL для временного доступа к файлу
 * @param {string} key - путь к файлу в bucket
 * @param {number} expiresIn - время жизни URL в секундах (по умолчанию 1 час)
 * @returns {Promise<string>} Presigned URL
 */
async function getPresignedUrl(key, expiresIn = 3600) {
  const command = new GetObjectCommand({
    Bucket: BUCKET_NAME,
    Key: key,
  })

  return await getSignedUrl(s3Client, command, { expiresIn })
}

module.exports = {
  uploadFile,
  deleteFile,
  getPresignedUrl,
}
