variable "scale_down_alarm_name" {
  type = string
}

variable "scaling_alarm_name" {
  type = string
}

# variable "scale_down_adjustment" {
#   type = list(string)

#   default = [
#     {
#       metric_interval_lower_bound = 0
#       scaling_adjustment          = 0
#     },
#   ]
# }

variable "resource_id" {
  type = string
}

variable "max_capacity" {
  type = string
}

variable "period" {
  type = string
}

variable "cooldown" {
  type = string
}

variable "queue_name" {
  type = string
}

# variable "step_adjustments" {
#   type = list(string)
# }

variable "adjustment_type" {
  type = string
}

