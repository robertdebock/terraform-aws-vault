resource "aws_cloudwatch_dashboard" "default" {
  count          = var.cloudwatch_agent ? 1 : 0
  dashboard_body = jsonencode(
    {
        "widgets": [
            {
                "height": 15,
                "width": 24,
                "y": 0,
                "x": 0,
                "type": "explorer",
                "properties": {
                    "labels": [],
                    "metrics": [],
                    "period": 60,
                    "region": "${data.aws_region.default.name}",
                    "splitBy": "",
                    "widgetOptions": {
                        "legend": {
                            "position": "bottom"
                        },
                        "rowsPerPage": 3,
                        "stacked": false,
                        "view": "timeSeries",
                        "widgetsPerRow": 2
                    }
                }
            },
            {
                "height": 6,
                "width": 12,
                "y": 15,
                "x": 12,
                "type": "metric",
                "properties": {
                    "metrics": [
                        [ { "expression": "SELECT MAX(disk_used_percent) FROM SCHEMA(CWAgent, AutoScalingGroupName,InstanceId,device,fstype,path) WHERE path = '${var.vault_path}' AND AutoScalingGroupName = '${aws_autoscaling_group.default.name}'", "label": "${var.vault_path}", "id": "q1", "region": "${data.aws_region.default.name}" } ],
                        [ "CWAgent", "disk_used_percent", "path", "${var.vault_path}", "InstanceId", "i-05f6d49155f255f0b", "AutoScalingGroupName", "${aws_autoscaling_group.default.name}", "device", "nvme1n1", "fstype", "ext4", { "id": "m1", "visible": false } ]
                    ],
                    "view": "gauge",
                    "stacked": false,
                    "region": "${data.aws_region.default.name}",
                    "stat": "Average",
                    "period": 300,
                    "yAxis": {
                        "left": {
                            "min": 0,
                            "max": 100
                        }
                    },
                    "title": "Disk usage (%)"
                }
            },
            {
                "type": "metric",
                "x": 0,
                "y": 15,
                "width": 12,
                "height": 6,
                "properties": {
                    "metrics": [
                        [ { "expression": "SELECT MAX(mem_used_percent) FROM CWAgent WHERE AutoScalingGroupName = '${aws_autoscaling_group.default.name}'", "label": "Maximum", "id": "q1" } ],
                        [ "CWAgent", "mem_used_percent", "InstanceId", "i-05f6d49155f255f0b", { "id": "m1", "visible": false } ]
                    ],
                    "view": "gauge",
                    "stacked": false,
                    "region": "${data.aws_region.default.name}",
                    "stat": "Average",
                    "period": 300,
                    "yAxis": {
                        "left": {
                            "min": 0,
                            "max": 100
                        }
                    },
                    "title": "Memory usage (%)"
                }
            }
        ]
    }
  )
  dashboard_name = "vault-${var.name}-${random_string.default.result}"
}