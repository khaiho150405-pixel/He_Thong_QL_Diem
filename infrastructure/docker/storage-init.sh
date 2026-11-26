#!/bin/sh
set -eu

mc alias set local http://minio:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" >/dev/null
mc mb --ignore-existing "local/$S3_BUCKET"
mc anonymous set none "local/$S3_BUCKET"

if [ -z "${S3_ACCESS_KEY:-}" ] || [ "$S3_ACCESS_KEY" = "$MINIO_ROOT_USER" ]; then
  echo "S3_ACCESS_KEY đang là tài khoản root của MinIO; không tạo tài khoản ứng dụng."
  exit 0
fi

policy="app-$S3_BUCKET"
cat >/tmp/app-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket", "s3:GetBucketLocation"],
      "Resource": ["arn:aws:s3:::$S3_BUCKET"]
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      "Resource": ["arn:aws:s3:::$S3_BUCKET/*"]
    }
  ]
}
EOF

mc admin user add local "$S3_ACCESS_KEY" "$S3_SECRET_KEY" >/dev/null
mc admin policy create local "$policy" /tmp/app-policy.json >/dev/null
if ! mc admin policy attach local "$policy" --user "$S3_ACCESS_KEY" >/dev/null 2>&1; then
  mc admin user info local "$S3_ACCESS_KEY" | grep -q "$policy"
fi
echo "Tài khoản ứng dụng chỉ có quyền trên bucket $S3_BUCKET đã sẵn sàng."
