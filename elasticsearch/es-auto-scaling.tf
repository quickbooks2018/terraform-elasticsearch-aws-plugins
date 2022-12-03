#######################
# ElasticSearch Cluster
#######################

##############
# Master Nodes
##############
module "launch-configuration-es-master" {

  source                    = "./modules/aws-launch-configuration"
  launch-configuration-name = "launch-configuration-es-master-nodes"
  ebs_optimized             = true
  iam_instance_profile_name = module.iam-instance-profile.ec2-instance-profile-name
  # Ubuntu
  image_id              = "ami-001db25c4878c938b"
  instance_type         = "t3a.medium"
  volume_size           = "30"
  volume_type           = "gp2"
  delete_on_termination = "true"
  encrypted             = "true"
  key_name              = module.ec2-keypair.key-name
  security_groups       = [module.ec2-sg-appsecgroup.security_group_id]
  enable_monitoring     = "true"
  user_data             = file("./modules/aws-launch-configuration/user-data/es-master.sh")

}


module "auto-scaling-es-master" {
  source                    = "./modules/aws-auto-scaling"
  autoscaling-group-name    = "auto-scaling-es-master-nodes"
  launch_configuration      = module.launch-configuration-es-master.launch_configuration_name
  max-size                  = "3"
  min-size                  = "3"
  health-check-grace-period = "300"
  desired-capacity          = "3"
  force-delete              = "false"
  #A list of subnet IDs to launch resources in
  vpc-zone-identifier = [module.vpc.private_subnets][0]
  target-group-arns   = [aws_lb_target_group.elastic-search-nodes.arn]
  health-check-type   = "EC2"
  key                 = "Name"
  value               = "es-master-node"
  role                = "role"
  role_value          = "elasticsearch"
}


############
# DATA Nodes
############
module "launch-configuration-es-data-nodes" {

  source                    = "./modules/aws-launch-configuration"
  launch-configuration-name = "launch-configuration-es-data-nodes"
  ebs_optimized             = true
  iam_instance_profile_name = module.iam-instance-profile.ec2-instance-profile-name
  # Ubuntu
  image_id              = "ami-001db25c4878c938b"
  instance_type         = "t3a.medium"
  volume_size           = "30"
  volume_type           = "gp2"
  delete_on_termination = "true"
  encrypted             = "true"
  key_name              = module.ec2-keypair.key-name
  security_groups       = [module.ec2-sg-appsecgroup.security_group_id]
  enable_monitoring     = "true"
  user_data             = file("./modules/aws-launch-configuration/user-data/es-data-node.sh")
}




module "auto-scaling-es-data-nodes" {
  source                    = "./modules/aws-auto-scaling"
  autoscaling-group-name    = "auto-scaling-es-data-nodes"
  launch_configuration      = module.launch-configuration-es-data-nodes.launch_configuration_name
  max-size                  = "2"
  min-size                  = "2"
  health-check-grace-period = "300"
  desired-capacity          = "2"
  force-delete              = "false"
  #A list of subnet IDs to launch resources in
  vpc-zone-identifier = [module.vpc.private_subnets][0]
  target-group-arns   = [aws_lb_target_group.elastic-search-nodes.arn]
  health-check-type   = "EC2"
  key                 = "Name"
  value               = "es-data-node"
  role                = "role"
  role_value          = "elasticsearch"
}




###########
# SNS Topic
###########
module "sns-topic-auto-scaling" {
  source                         = "./modules/aws-sns"
  auto-scaling-sns-name          = "ES-AutoScaling-SNS-Topic"
  sns-subscription-email-address = "info@cloudgeeks.ca"
}

module "auto-scaling-sns" {
  source                       = "./modules/aws-auto-scaling-sns"
  aws_autoscaling_notification = [module.auto-scaling-es-master.autoscaling-group-name, module.auto-scaling-es-data-nodes.autoscaling-group-name][0]
  sns-topic-arn                = module.sns-topic-auto-scaling.auto-scaling-sns-arn
}
