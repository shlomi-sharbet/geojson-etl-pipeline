# ecr.tf — מאגר תמונות לקונטיינר Lambda
resource "aws_ecr_repository" "lambda_repo" {
  name                 = "asterra/geojson-processor"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
}



# ECR auth/token + proxy endpoint (עוזר ל-login מול registry)
## data "aws_ecr_authorization_token" "ecr" {}

# Build & Push ב-apply אחד דרך null_resource

# resource "null_resource" "docker_build_and_push" {
#   depends_on = [aws_ecr_repository.lambda_repo]

#   # טריגרים לריצה מחדש רק כשיש שינוי בקוד/תג/Repo
#   triggers = {
#     dockerfile_sha = filesha256("${path.module}/Dockerfile")
#     app_sha        = filesha256("${path.module}/app.py")
#     repo_url       = aws_ecr_repository.lambda_repo.repository_url
#     image_tag      = var.lambda_image_tag
# ##    registry_host  = replace(data.aws_ecr_authorization_token.ecr.proxy_endpoint, "http://", "")
#     registry_host  = replace(aws_ecr_repository.lambda_repo.repository_url, "/asterra/geojson-processor", "")
#   }

# #   provisioner "local-exec" {
# #     interpreter = ["/bin/bash", "-c"]
# #     command = <<-EOT
# #       set -euo pipefail
# #       echo "[INFO] Docker login to ${self.triggers.registry_host}"
# #       awslocal ecr get-login-password --region us-east-1 | \
# #         docker login --username AWS --password-stdin ${self.triggers.registry_host}

# #       echo "[INFO] Building image geojson-processor:${self.triggers.image_tag}"
# #       docker build -t geojson-processor:${self.triggers.image_tag} .

# #       echo "[INFO] Tag & Push to ${self.triggers.repo_url}:${self.triggers.image_tag}"
# #       docker tag geojson-processor:${self.triggers.image_tag} ${self.triggers.repo_url}:${self.triggers.image_tag}
# #       docker push ${self.triggers.repo_url}:${self.triggers.image_tag}
# #     EOT
# #   }
# # }
#   provisioner "local-exec" {
#     interpreter = ["/bin/bash","-c"]
#     command = "set -euo pipefail && echo \"[INFO] Docker login to ${self.triggers.registry_host}\" && awslocal ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${self.triggers.registry_host} && echo \"[INFO] Building image geojson-processor:${self.triggers.image_tag}\" && docker build -t geojson-processor:${self.triggers.image_tag} . && echo \"[INFO] Tag & Push to ${self.triggers.repo_url}:${self.triggers.image_tag}\" && docker tag geojson-processor:${self.triggers.image_tag} ${self.triggers.repo_url}:${self.triggers.image_tag} && docker push ${self.triggers.repo_url}:${self.triggers.image_tag}"
#   }
# }
