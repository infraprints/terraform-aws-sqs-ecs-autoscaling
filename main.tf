resource "aws_cloudwatch_metric_alarm" "empty" {
  alarm_name          = var.scale_down_alarm_name
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = "2"
  evaluation_periods  = "2"
  alarm_actions       = [aws_appautoscaling_policy.sqs_empty.arn]

  metric_query {
    id          = "e1"
    label       = "ApproximateNumberOfMessages"
    expression  = "m1+m2"
    return_data = true
  }

  metric_query {
    id = "m1"

    metric {
      namespace   = "AWS/SQS"
      metric_name = "ApproximateNumberOfMessagesVisible"
      period      = var.period
      stat        = "Maximum"

      dimensions = {
        QueueName = var.queue_name
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      namespace   = "AWS/SQS"
      metric_name = "ApproximateNumberOfMessagesNotVisible"
      period      = var.period
      stat        = "Maximum"

      dimensions = {
        QueueName = var.queue_name
      }
    }
  }

  depends_on = [aws_appautoscaling_policy.sqs]
}

resource "aws_cloudwatch_metric_alarm" "scale" {
  alarm_name          = var.scaling_alarm_name
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "1"
  evaluation_periods  = "1"
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibilty in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  alarm_actions = [aws_appautoscaling_policy.sqs.arn]

  metric_query {
    id          = "e1"
    label       = "ApproximateNumberOfMessages"
    expression  = "m1+m2"
    return_data = true
  }

  metric_query {
    id = "m1"

    metric {
      namespace   = "AWS/SQS"
      metric_name = "ApproximateNumberOfMessagesVisible"
      period      = var.period
      stat        = "Average"

      dimensions = {
        QueueName = var.queue_name
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      namespace   = "AWS/SQS"
      metric_name = "ApproximateNumberOfMessagesNotVisible"
      period      = var.period
      stat        = "Average"

      dimensions = {
        QueueName = var.queue_name
      }
    }
  }

  depends_on = [aws_appautoscaling_policy.sqs]
}

resource "aws_appautoscaling_target" "default" {
  max_capacity       = var.max_capacity
  min_capacity       = 0
  resource_id        = var.resource_id
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "scale" {
  policy_type        = "StepScaling"
  name               = "ScaleBySQS"
  resource_id        = var.resource_id
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = var.adjustment_type
    cooldown                = var.cooldown
    metric_aggregation_type = "Maximum"
    dynamic "step_adjustment" {
      for_each = var.step_adjustments
      content {
        # TF-UPGRADE-TODO: The automatic upgrade tool can't predict
        # which keys might be set in maps assigned here, so it has
        # produced a comprehensive set here. Consider simplifying
        # this after confirming which keys can be set in practice.

        metric_interval_lower_bound = lookup(step_adjustment.value, "metric_interval_lower_bound", null)
        metric_interval_upper_bound = lookup(step_adjustment.value, "metric_interval_upper_bound", null)
        scaling_adjustment          = step_adjustment.value.scaling_adjustment
      }
    }
  }

  depends_on = [aws_appautoscaling_target.default]
}

resource "aws_appautoscaling_policy" "empty" {
  name        = "ZeroOnEmpty"
  resource_id = var.resource_id

  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
  policy_type        = "StepScaling"

  step_scaling_policy_configuration {
    adjustment_type         = "ExactCapacity"
    cooldown                = var.cooldown
    metric_aggregation_type = "Maximum"
    dynamic "step_adjustment" {
      for_each = var.scale_down_adjustment
      content {
        # TF-UPGRADE-TODO: The automatic upgrade tool can't predict
        # which keys might be set in maps assigned here, so it has
        # produced a comprehensive set here. Consider simplifying
        # this after confirming which keys can be set in practice.

        metric_interval_lower_bound = lookup(step_adjustment.value, "metric_interval_lower_bound", null)
        metric_interval_upper_bound = lookup(step_adjustment.value, "metric_interval_upper_bound", null)
        scaling_adjustment          = step_adjustment.value.scaling_adjustment
      }
    }
  }

  depends_on = [aws_appautoscaling_target.default]
}

