# Reference: https://cert-manager.io/docs/configuration/acme/dns01/route53/
resource "aws_iam_role" "cert_manager" {
  name = "${var.env_name}-cert-manager-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "manage_route53_zones"
    policy = jsonencode({
      "Version" = "2012-10-17",
      "Statement" = [
        {
          "Effect"   = "Allow",
          "Action"   = "route53:GetChange",
          "Resource" = "arn:aws:route53:::change/*"
        },
        {
          "Effect" = "Allow",
          "Action" = [
            "route53:ChangeResourceRecordSets",
            "route53:ListResourceRecordSets"
          ],
          "Resource" = "arn:aws:route53:::hostedzone/*"
        }
      ]
    })
  }
}
