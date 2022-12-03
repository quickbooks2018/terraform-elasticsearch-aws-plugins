resource "aws_iam_instance_profile" "this" {
  name = var.aws_iam_instance_profile_name
  role = aws_iam_role.role.name
}

resource "aws_iam_role" "role" {
  name = var.aws_iam_role_name
  path = "/"


  # EC2 Assumed Role Policy

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": ["ec2.amazonaws.com"]
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}


# Custom policy attachment / Customer Managed policy
resource "aws_iam_policy" "custom-policy" {
  name        = var.custom-policy-name
  path        = "/"
  description = "Custom Policy"


  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Sid : "VisualEditor0",
        Effect : "Allow",
        Action : [
          "logs:CreateLogStream*",
          "logs:PutLogEvents*",
          "cloudwatch:Put*",
          "logs:List*",
          "logs:Put",
          "ec2:DescribeInstances",
          "ec2:Describe*",
          "ec2messages:*",
          "s3:List*",
          "s3:Put*",
          "s3:Get*",
          "ssmmessages:*",
          "ssm:*"
        ],
        Resource : "*"
      }
    ]
  })
}


# AWS Custom Policy Attachment to a role created above
resource "aws_iam_policy_attachment" "custom-policy-attachment" {
  name       = "custom-policy-attachment"
  roles      = [aws_iam_role.role.name]
  policy_arn = aws_iam_policy.custom-policy.arn
}




# AWS Existing policy attachment/ AWS Managed Policy
data "aws_iam_policy" "ssm-ec2-console" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy_attachment" "ssm-ec2-console" {
  name       = "ssm-ec2-console"
  roles      = [aws_iam_role.role.name]
  policy_arn = data.aws_iam_policy.ssm-ec2-console.arn
}




# Custom policy attachment / Customer Managed policy
resource "aws_iam_policy" "rout53-custom-policy" {
  name        = "rout53-custom-policy"
  path        = "/"
  description = "Route53 Custom Policy"


  policy = jsonencode({


    "Version" : "2012-10-17",
    "Statement" : [
      {
        Sid : "AllowHostedZonePermissions",
        Effect : "Allow",
        Action : [
          "route53:UpdateHostedZoneComment",
          "route53:GetHostedZone",
          "route53:ListHostedZones",
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets",
          "route53:GetHostedZoneCount",
          "route53:ListHostedZonesByName",
          "route53resolver:CreateResolverEndpoint",
          "route53resolver:ListResolverEndpoints",
          "ec2:CreateNetworkInterface",
          "ec2:CreateNetworkInterfacePermission",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs"
        ],
        Resource : "*"
      },


      {
        Sid : "AllowHealthCheckPermissions",
        Effect : "Allow",
        Action : [
          "route53:CreateHealthCheck",
          "route53:UpdateHealthCheck",
          "route53:GetHealthCheck",
          "route53:ListHealthChecks",
          "route53:GetCheckerIpRanges",
          "route53:GetHealthCheckCount",
          "route53:GetHealthCheckStatus",
          "route53:GetHealthCheckLastFailureReason"
        ],
        Resource : "*"
      }





    ]






  })
}


# AWS Custom Policy Attachment to a role created above
resource "aws_iam_policy_attachment" "rout53-custom-policy" {
  name       = "rout53-custom-policy"
  roles      = [aws_iam_role.role.name]
  policy_arn = aws_iam_policy.rout53-custom-policy.arn
}
