#AUTO-SCALING VARIABLES

variable "autoscaling-group-name" {
  default = ""
}

variable "launch_configuration" {
  default = ""
}

variable "max-size" {
  default = ""
}

variable "min-size" {
  default = ""
}

variable "health-check-grace-period" {
  default = ""
}

variable "desired-capacity" {
  default = ""
}

variable "force-delete" {
  default = ""
}

variable "vpc-zone-identifier" {
  type = list(string)
}

variable "target-group-arns" {
  default = []
}

variable "health-check-type" {
  default = ""
}

# TAGS
# Note: These are not normal tags, these are auto-scaling group tags

variable "key" {
  default = ""
}

variable "value" {
  default = ""
}

variable "role" {
  default = ""
}

variable "role_value" {
  default = ""
}


#Auto-Scaling-Policy-Scale-up
variable "auto-scaling-policy-name-scale-up" {
  default = ""
}

variable "adjustment-type-scale-up" {
  default = ""
}

variable "scaling-adjustment-scale-up" {
  default = ""
}

variable "cooldown-scale-up" {
  default = ""
}

variable "policy-type-scale-up" {
  default = ""
}

#Auto-Scaling Policy Cloud-Watch Alarm-Scale-up
variable "alarm-name-scale-up" {
  default = ""
}

variable "comparison-operator-scale-up" {
  default = ""
}

variable "evaluation-periods-scale-up" {
  default = ""
}

variable "metric-name-scale-up" {
  default = ""
}

variable "namespace-scale-up" {
  default = ""
}

variable "period-scale-up" {
  default = ""
}

variable "statistic-scale-up" {
  default = ""
}

variable "threshold-scale-up" {
  default = ""
}

variable "adjustment-type" {
  default = ""
}

#Auto-Scaling Policy Scale-down

variable "auto-scaling-policy-name-scale-down" {
  default = ""
}

variable "adjustment-type-scale-down" {
  default = ""
}

variable "scaling-adjustment-scale-down" {
  default = ""
}

variable "cooldown-scale-down" {
  default = ""
}

variable "policy-type-scale-down" {
  default = ""
}

#Auto-Scaling Policy Cloud-Watch Alarm-Scale-down
variable "alarm-name-scale-down" {
  default = ""
}

variable "comparison-operator-scale-down" {
  default = ""
}

variable "evaluation-periods-scale-down" {
  default = ""
}

variable "metric-name-scale-down" {
  default = ""
}

variable "namespace-scale-down" {
  default = ""
}

variable "period-scale-down" {
  default = ""
}

variable "statistic-scale-down" {
  default = ""
}

variable "threshold-scale-down" {
  default = ""
}

#Application Load Balancer Target Group
variable "alb-tg-name" {
  default = ""
}
variable "target-group-port" {
  default = ""
}

variable "target-group-protocol" {
  default = ""
}

variable "vpc-id" {
  default = ""
}
