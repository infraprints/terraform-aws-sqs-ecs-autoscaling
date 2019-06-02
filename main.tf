
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
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
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
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.default]
}

resource "aws_cloudwatch_metric_alarm" "empty" {
  alarm_name          = var.scale_down_alarm_name
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = "2"
  evaluation_periods  = "2"
  alarm_actions       = [aws_appautoscaling_policy.empty.arn]

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

  depends_on = [aws_appautoscaling_policy.scale]
}

resource "aws_cloudwatch_metric_alarm" "scale" {
  alarm_name          = var.scaling_alarm_name
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "1"
  evaluation_periods  = "1"
  alarm_actions       = [aws_appautoscaling_policy.scale.arn]

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
}
