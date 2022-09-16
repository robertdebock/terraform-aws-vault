resource "aws_cloudwatch_dashboard" "default" {
  count          = var.vault_enable_cloudwatch ? 1 : 0
  dashboard_body = <<EOF
{
    "widgets": [
        {
            "height": 6,
            "width": 12,
            "y": 6,
            "x": 6,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ { "expression": "SELECT MAX(CPUUtilization) FROM SCHEMA(\"AWS/EC2\", AutoScalingGroupName) WHERE AutoScalingGroupName = '${var.vault_name}' GROUP BY AutoScalingGroupName", "label": "CPU (%) utilization ASG", "id": "q1", "region": "${data.aws_region.default.name}", "period": 60, "color": "#17becf" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "region": "${data.aws_region.default.name}",
                "stat": "Average",
                "period": 60,
                "title": "ASG - CPU (%) utilisation",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100,
                        "showUnits": false
                    },
                    "right": {
                        "showUnits": false
                    }
                },
                "legend": {
                    "position": "hidden"
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 12,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ { "expression": "SELECT MAX(disk_used_percent) FROM SCHEMA(\"${local.instance_name}_cwagent\", AutoScalingGroupName,InstanceId,device,fstype,path) WHERE AutoScalingGroupName = '${var.vault_name}' AND path = '${var.vault_data_path}' GROUP BY InstanceId", "label": "", "id": "q1", "region": "${data.aws_region.default.name}" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${data.aws_region.default.name}",
                "stat": "Average",
                "period": 60,
                "title": "(%) Disk used per node - ${var.vault_data_path}",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100,
                        "showUnits": false
                    },
                    "right": {
                        "showUnits": false
                    }
                },
                "legend": {
                    "position": "hidden"
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 18,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ { "expression": "SELECT MAX(disk_used_percent) FROM SCHEMA(\"${local.instance_name}_cwagent\", AutoScalingGroupName,InstanceId,device,fstype,path) WHERE AutoScalingGroupName = '${var.vault_name}' AND path = '/' GROUP BY InstanceId", "label": "", "id": "q1", "period": 60, "region": "${data.aws_region.default.name}" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${data.aws_region.default.name}",
                "stat": "Average",
                "period": 60,
                "title": "(%) Disk used per node - /",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100,
                        "label": "",
                        "showUnits": false
                    },
                    "right": {
                        "showUnits": false
                    }
                },
                "legend": {
                    "position": "hidden"
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 24,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", "watch", { "color": "#7f7f7f" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "title": "ASG - In Service Instances (Count)",
                "region": "${data.aws_region.default.name}",
                "period": 60,
                "stat": "Average",
                "yAxis": {
                    "left": {
                        "showUnits": false
                    },
                    "right": {
                        "showUnits": false
                    }
                },
                "legend": {
                    "position": "hidden"
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 24,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/AutoScaling", "GroupTerminatingInstances", "AutoScalingGroupName", "watch", { "color": "#d62728" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "title": "ASG - Terminating Instances (Count)",
                "region": "${data.aws_region.default.name}",
                "period": 60,
                "stat": "Average",
                "yAxis": {
                    "left": {
                        "showUnits": false
                    },
                    "right": {
                        "showUnits": false
                    }
                },
                "legend": {
                    "position": "hidden"
                }
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 18,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ { "expression": "SELECT AVG(NetworkIn) FROM SCHEMA(\"AWS/EC2\", AutoScalingGroupName) WHERE AutoScalingGroupName = '${var.vault_name}'", "label": "Netwerk In (Bytes)", "id": "q1", "region": "${data.aws_region.default.name}", "color": "#9467bd" } ],
                    [ "AWS/EC2", "NetworkIn", "AutoScalingGroupName", "watch", { "id": "m1", "visible": false } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "title": "ASG - Network In (Bytes)",
                "region": "${data.aws_region.default.name}",
                "period": 60,
                "stat": "Average",
                "yAxis": {
                    "left": {
                        "showUnits": false
                    },
                    "right": {
                        "showUnits": false
                    }
                },
                "legend": {
                    "position": "hidden"
                }
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 18,
            "x": 18,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/EC2", "NetworkOut", "AutoScalingGroupName", "watch", { "color": "#9467bd", "label": "Network Out (Bytes)" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "title": "ASG - Network Out (Bytes)",
                "region": "${data.aws_region.default.name}",
                "period": 60,
                "stat": "Average",
                "yAxis": {
                    "left": {
                        "showUnits": false
                    },
                    "right": {
                        "showUnits": false
                    }
                },
                "legend": {
                    "position": "hidden"
                }
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 12,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ { "expression": "SELECT MAX(mem_used_percent) FROM SCHEMA(\"${local.instance_name}_cwagent\", AutoScalingGroupName,InstanceId) WHERE AutoScalingGroupName = '${var.vault_name}' GROUP BY InstanceId", "label": "", "id": "q1", "period": 60, "region": "${data.aws_region.default.name}" } ],
                    [ "CWAgent", "mem_used_percent", "InstanceId", "i-0add6009056a2d366", "AutoScalingGroupName", "watch", { "id": "m1", "visible": false } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${data.aws_region.default.name}",
                "stat": "Average",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100,
                        "showUnits": false
                    },
                    "right": {
                        "showUnits": false
                    }
                },
                "legend": {
                    "position": "hidden"
                },
                "title": "(%) Memory used per node"
            }
        },
        {
            "height": 6,
            "width": 12,
            "y": 30,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", "watch", { "color": "#7f7f7f" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "title": "Desired Capacity (Count)",
                "region": "${data.aws_region.default.name}",
                "period": 60,
                "stat": "Average",
                "yAxis": {
                    "left": {
                        "showUnits": false
                    },
                    "right": {
                        "showUnits": false
                    }
                },
                "legend": {
                    "position": "hidden"
                }
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 6,
            "x": 18,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/ApplicationELB", "RequestCount", "TargetGroup", "${aws_lb_target_group.api.arn_suffix}", "LoadBalancer", "${aws_lb.api.arn_suffix}", { "label": "${aws_lb_target_group.api.name}", "color": "#9edae5" } ]
                ],
                "period": 60,
                "region": "${data.aws_region.default.name}",
                "stat": "Sum",
                "title": "ELB - Requests",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "showUnits": false
                    },
                    "right": {
                        "showUnits": false
                    }
                },
                "view": "timeSeries",
                "stacked": true,
                "legend": {
                    "position": "hidden"
                }
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 0,
            "x": 12,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ { "expression": "SELECT MAX(disk_used_percent) FROM SCHEMA(\"${local.instance_name}_cwagent\", AutoScalingGroupName,InstanceId,device,fstype,path) WHERE path = '/'", "label": "Max used disk - /", "id": "q1", "region": "${data.aws_region.default.name}", "period": 60, "color": "#2ca02c" } ]
                ],
                "view": "gauge",
                "region": "${data.aws_region.default.name}",
                "stat": "Average",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100
                    }
                },
                "title": "Max used disk - /"
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 0,
            "x": 18,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ { "expression": "SELECT MAX(disk_used_percent) FROM SCHEMA(\"${local.instance_name}_cwagent\", AutoScalingGroupName,InstanceId,device,fstype,path) WHERE path = '${var.vault_data_path}'", "label": "Max used disk - ${var.vault_data_path}", "id": "q1", "region": "${data.aws_region.default.name}", "period": 60, "color": "#2ca02c" } ]
                ],
                "view": "gauge",
                "region": "${data.aws_region.default.name}",
                "stat": "Average",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100
                    }
                },
                "title": "Max used disk - ${var.vault_data_path}",
                "stacked": false
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 6,
            "x": 0,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ { "expression": "SELECT MAX(mem_used_percent) FROM SCHEMA(\"${local.instance_name}_cwagent\", AutoScalingGroupName,InstanceId)", "label": "Max memory used", "id": "q1", "region": "${data.aws_region.default.name}", "period": 60, "color": "#2ca02c" } ]
                ],
                "view": "gauge",
                "region": "${data.aws_region.default.name}",
                "stat": "Average",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100
                    }
                },
                "title": "Max memory used",
                "stacked": false
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 0,
            "x": 0,
            "type": "metric",
            "properties": {
                "sparkline": true,
                "metrics": [
                    [ { "expression": "SELECT MAX(HealthyHostCount) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer,TargetGroup) WHERE TargetGroup = '${aws_lb_target_group.api.arn_suffix}' AND LoadBalancer = '${aws_lb.api.arn_suffix}'", "label": "Query1", "id": "q1", "visible": false, "region": "${data.aws_region.default.name}" } ],
                    [ "AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", "${aws_lb_target_group.api.arn_suffix}", "LoadBalancer", "${aws_lb.api.arn_suffix}", { "label": "${aws_lb_target_group.api.name}", "color": "#2ca02c", "id": "m1" } ]
                ],
                "period": 60,
                "region": "${data.aws_region.default.name}",
                "stat": "Average",
                "title": "Healthy Hosts",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": ${local.amount}
                    }
                },
                "view": "gauge",
                "stacked": false,
                "legend": {
                    "position": "hidden"
                }
            }
        },
        {
            "height": 6,
            "width": 6,
            "y": 0,
            "x": 6,
            "type": "metric",
            "properties": {
                "metrics": [
                    [ { "expression": "SELECT MAX(UnHealthyHostCount) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer,TargetGroup) WHERE TargetGroup = '${aws_lb_target_group.api.arn_suffix}' AND LoadBalancer = '${aws_lb.api.arn_suffix}'", "label": "Query1", "id": "q1", "region": "${data.aws_region.default.name}", "color": "#d62728" } ],
                    [ "AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", "${aws_lb_target_group.api.arn_suffix}", "LoadBalancer", "${aws_lb.api.arn_suffix}", { "label": "${aws_lb_target_group.api.name}", "color": "#2ca02c", "id": "m1", "visible": false } ]
                ],
                "sparkline": true,
                "period": 60,
                "region": "${data.aws_region.default.name}",
                "stat": "Average",
                "title": "Unhealthy Hosts",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": ${local.amount}
                    }
                },
                "view": "gauge",
                "stacked": false,
                "legend": {
                    "position": "hidden"
                }
            }
        }
    ]
}
EOF
  dashboard_name = "vault-${var.vault_name}"
}
