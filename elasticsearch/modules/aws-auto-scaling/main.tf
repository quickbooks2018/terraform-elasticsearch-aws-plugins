resource "aws_autoscaling_group" "autoscaling-group" {
  name                      = var.autoscaling-group-name
  launch_configuration      = var.launch_configuration
  max_size                  = var.max-size
  min_size                  = var.min-size
  health_check_grace_period = var.health-check-grace-period
  #Group-Size or desired capacity
  desired_capacity = var.desired-capacity
  force_delete     = var.force-delete
  #A list of subnet IDs to launch resources in
  vpc_zone_identifier = var.vpc-zone-identifier
  health_check_type   = var.health-check-type
  target_group_arns   = var.target-group-arns
  tag {
    key                 = var.key
    propagate_at_launch = true
    value               = var.value
  }
  
   tag {
    key                 = var.role
    propagate_at_launch = true
    value               = var.role_value
  }


  lifecycle {
    prevent_destroy = true
  }

  protect_from_scale_in = true


}

