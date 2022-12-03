##########################
# ElasticSearch Monitoring
##########################
module "launch-configuration-es-monitoring" {

  source                    = "./modules/aws-launch-configuration"
  launch-configuration-name = "launch-configuration-es-monitoring"
  ebs_optimized             = true
  iam_instance_profile_name = module.iam-instance-profile.ec2-instance-profile-name
  # Ubuntu
  image_id              = "ami-08c40ec9ead489470"
  instance_type         = "t3a.medium"
  volume_size           = "30"
  volume_type           = "gp2"
  delete_on_termination = "true"
  encrypted             = "true"
  key_name              = module.ec2-keypair.key-name
  security_groups       = [module.ec2-sg-appsecgroup.security_group_id]
  enable_monitoring     = "true"
  user_data             = file("./modules/aws-launch-configuration/user-data/es-monitoring.sh")

}


module "auto-scaling-es-monitoring" {
  source                    = "./modules/aws-auto-scaling"
  autoscaling-group-name    = "auto-scaling-es-monitoring"
  launch_configuration      = module.launch-configuration-es-monitoring.launch_configuration_name
  max-size                  = "1"
  min-size                  = "1"
  health-check-grace-period = "300"
  desired-capacity          = "1"
  force-delete              = "true"
  #A list of subnet IDs to launch resources in
  vpc-zone-identifier = [module.vpc.public_subnets][0]
  health-check-type   = "EC2"
  key                 = "Name"
  value               = "es-monitoring"
}



###########
# SNS Topic
###########
module "es-monitoring-sns-topic-auto-scaling" {
  source                         = "./modules/aws-sns"
  auto-scaling-sns-name          = "ES-Monitoring-AutoScaling-SNS-Topic"
  sns-subscription-email-address = "info@cloudgeeks.ca"
}

#########################
# Add Auto Scaling Groups
#########################
module "es-monitoring-auto-scaling-sns" {
  source                       = "./modules/aws-auto-scaling-sns"
  aws_autoscaling_notification = [module.auto-scaling-es-monitoring.autoscaling-group-name][0]
  sns-topic-arn                = module.es-monitoring-sns-topic-auto-scaling.auto-scaling-sns-arn
}