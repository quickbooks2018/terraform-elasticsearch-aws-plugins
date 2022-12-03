#OUTPUT
output "aws-alb-id" {
  value = aws_lb.alb.id
}

output "aws-alb-arn" {
  value = aws_lb.alb.arn
}

output "aws-alb-arn-suffix" {
  value = aws_lb.alb.arn_suffix
}

output "aws-alb-dns-name" {
  value = aws_lb.alb.dns_name
}

output "aws-alb-name" {
  value = aws_lb.alb.name
}

output "aws-alb-hosted-zone-id" {
  value = aws_lb.alb.zone_id
}