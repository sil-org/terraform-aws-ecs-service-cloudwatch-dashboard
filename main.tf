resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = var.dashboard_name
  dashboard_body = jsonencode({
    widgets = local.widgets
  })
}

data "aws_region" "current" {}

locals {
  aws_region = data.aws_region.current.region

  cluster_widget = {
    type   = "metric"
    width  = 18
    height = 6
    properties = {
      view    = "timeSeries"
      stacked = false
      metrics = [
        ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, { color = "#d62728" }],
        [".", "CPUReservation", ".", ".", { color = "#ff7f0e" }],
        [".", "MemoryUtilization", ".", ".", { yAxis = "right", color = "#1f77b4" }],
        [".", "MemoryReservation", ".", ".", { yAxis = "right", color = "#17becf" }]
      ]
      stat   = "Maximum"
      region = local.aws_region,
      annotations = {
        horizontal = [
          {
            color = "#ff9896"
            label = "100% CPU"
            value = 100
          },
          {
            color = "#9edae5"
            label = "100% Memory"
            value = 100
            yAxis = "right"
          }
        ]
      }
      yAxis = {
        left = {
          min = 0
        }
        right = {
          min = 0
        }
      }
      title  = "${var.cluster_name} (cluster)"
      period = 300
    }
  }

  service_widgets = [for service_name in var.service_names : {
    type   = "metric"
    width  = 18
    height = 6
    properties = {
      view    = "timeSeries"
      stacked = false
      metrics = [
        ["AWS/ECS", "CPUUtilization", "ServiceName", service_name, "ClusterName", var.cluster_name, { color = "#d62728", stat = "Maximum" }],
        [".", "MemoryUtilization", ".", ".", ".", ".", { yAxis = "right", color = "#1f77b4", stat = "Maximum" }]
      ]
      region = local.aws_region,
      annotations = {
        horizontal = [
          {
            color = "#ff9896",
            label = "100% CPU",
            value = 100
          },
          {
            color = "#9edae5",
            label = "100% Memory",
            value = 100,
            yAxis = "right"
          },
        ]
      }
      yAxis = {
        left = {
          min = 0
        }
        right = {
          min = 0
        }
      }
      title  = "${var.cluster_name} / ${service_name}"
      period = 300
    }
  }]

  widgets = concat([local.cluster_widget], local.service_widgets)
}
