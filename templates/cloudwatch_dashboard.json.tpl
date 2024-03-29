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
                    [ { "expression": "SELECT MAX(CPUUtilization) FROM SCHEMA(\"AWS/EC2\", AutoScalingGroupName) WHERE AutoScalingGroupName = '${asg_name}' GROUP BY AutoScalingGroupName", "label": "CPU (%) utilization ASG", "id": "q1", "region": "${aws_region}", "period": 60, "color": "#17becf" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "region": "${aws_region}",
                "stat": "Average",
                "period": 60,
                "title": "ASG - CPU utilisation (%)",
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
                    [ { "expression": "SELECT MAX(disk_used_percent) FROM SCHEMA(\"${vault_cloudwatch_namespace}\", AutoScalingGroupName,InstanceId,device,fstype,path) WHERE AutoScalingGroupName = '${asg_name}' AND path = '${vault_data_path}' GROUP BY InstanceId", "label": "", "id": "q1", "region": "${aws_region}" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${aws_region}",
                "stat": "Average",
                "period": 60,
                "title": "Disk usage per node (%) - ${vault_data_path}",
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
                    [ { "expression": "SELECT MAX(disk_used_percent) FROM SCHEMA(\"${vault_cloudwatch_namespace}\", AutoScalingGroupName,InstanceId,device,fstype,path) WHERE AutoScalingGroupName = '${asg_name}' AND path = '/' GROUP BY InstanceId", "label": "", "id": "q1", "period": 60, "region": "${aws_region}" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${aws_region}",
                "stat": "Average",
                "period": 60,
                "title": "Disk usage per node (%) - /",
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
                    [ "AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", "${asg_name}", { "color": "#7f7f7f" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "title": "ASG - In Service Instances (Count)",
                "region": "${aws_region}",
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
                    [ "AWS/AutoScaling", "GroupTerminatingInstances", "AutoScalingGroupName", "${asg_name}", { "color": "#d62728" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "title": "ASG - Terminating Instances (Count)",
                "region": "${aws_region}",
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
                    [ { "expression": "SELECT AVG(NetworkIn) FROM SCHEMA(\"AWS/EC2\", AutoScalingGroupName) WHERE AutoScalingGroupName = '${asg_name}'", "label": "Netwerk In (Bytes)", "id": "q1", "region": "${aws_region}", "color": "#9467bd" } ],
                    [ "AWS/EC2", "NetworkIn", "AutoScalingGroupName", "${asg_name}", { "id": "m1", "visible": false } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "title": "ASG - Network In (Bytes)",
                "region": "${aws_region}",
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
                    [ "AWS/EC2", "NetworkOut", "AutoScalingGroupName", "${asg_name}", { "color": "#9467bd", "label": "Network Out (Bytes)" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "title": "ASG - Network Out (Bytes)",
                "region": "${aws_region}",
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
                    [ { "expression": "SELECT MAX(mem_used_percent) FROM SCHEMA(\"${vault_cloudwatch_namespace}\", AutoScalingGroupName,InstanceId) WHERE AutoScalingGroupName = '${asg_name}' GROUP BY InstanceId", "label": "", "id": "q1", "period": 60, "region": "${aws_region}" } ],
                    [ "CWAgent", "mem_used_percent", "InstanceId", "i-0add6009056a2d366", "AutoScalingGroupName", "watch", { "id": "m1", "visible": false } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${aws_region}",
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
                "title": "Memory used per node (%)"
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
                    [ "AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", "${asg_name}", { "color": "#7f7f7f" } ]
                ],
                "view": "timeSeries",
                "stacked": true,
                "title": "ASG - Desired Capacity (Count)",
                "region": "${aws_region}",
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
                    [ "AWS/ApplicationELB", "RequestCount", "TargetGroup", "${aws_lb_target_group_arn}", "LoadBalancer", "${aws_lb_api_arn}", { "label": "${aws_lb_target_group_name}", "color": "#9edae5" } ]
                ],
                "period": 60,
                "region": "${aws_region}",
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
                    [ { "expression": "SELECT MAX(disk_used_percent) FROM SCHEMA(\"${vault_cloudwatch_namespace}\", AutoScalingGroupName,InstanceId,device,fstype,path) WHERE path = '/'", "label": "disk usage - /", "id": "q1", "region": "${aws_region}", "period": 60, "color": "#2ca02c" } ]
                ],
                "view": "gauge",
                "region": "${aws_region}",
                "stat": "Average",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100
                    }
                },
                "title": "Highest disk usage (in cluster) - /"
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
                    [ { "expression": "SELECT MAX(disk_used_percent) FROM SCHEMA(\"${vault_cloudwatch_namespace}\", AutoScalingGroupName,InstanceId,device,fstype,path) WHERE path = '${vault_data_path}'", "label": "disk usage - ${vault_data_path}", "id": "q1", "region": "${aws_region}", "period": 60, "color": "#2ca02c" } ]
                ],
                "view": "gauge",
                "region": "${aws_region}",
                "stat": "Average",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100
                    }
                },
                "title": "Highest disk usage (in cluster) - ${vault_data_path}",
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
                    [ { "expression": "SELECT MAX(mem_used_percent) FROM SCHEMA(\"${vault_cloudwatch_namespace}\", AutoScalingGroupName,InstanceId)", "label": "memory usage", "id": "q1", "region": "${aws_region}", "period": 60, "color": "#2ca02c" } ]
                ],
                "view": "gauge",
                "region": "${aws_region}",
                "stat": "Average",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100
                    }
                },
                "title": "Highest memory usage (in cluster)",
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
                    [ { "expression": "SELECT MAX(HealthyHostCount) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer,TargetGroup) WHERE TargetGroup = '${aws_lb_target_group_arn}' AND LoadBalancer = '${aws_lb_api_arn}'", "label": "Query1", "id": "q1", "visible": false, "region": "${aws_region}" } ],
                    [ "AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", "${aws_lb_target_group_arn}", "LoadBalancer", "${aws_lb_api_arn}", { "label": "${aws_lb_target_group_name}", "color": "#2ca02c", "id": "m1" } ]
                ],
                "period": 60,
                "region": "${aws_region}",
                "stat": "Average",
                "title": "Healthy Hosts - ELB (port 8200)",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": ${amount}
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
                    [ { "expression": "SELECT MAX(UnHealthyHostCount) FROM SCHEMA(\"AWS/ApplicationELB\", LoadBalancer,TargetGroup) WHERE TargetGroup = '${aws_lb_target_group_arn}' AND LoadBalancer = '${aws_lb_api_arn}'", "label": "Query1", "id": "q1", "region": "${aws_region}", "color": "#d62728" } ],
                    [ "AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", "${aws_lb_target_group_arn}", "LoadBalancer", "${aws_lb_api_arn}", { "label": "${aws_lb_target_group_name}", "color": "#2ca02c", "id": "m1", "visible": false } ]
                ],
                "sparkline": true,
                "period": 60,
                "region": "${aws_region}",
                "stat": "Average",
                "title": "Unhealthy Hosts - ELB (port 8200)",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": ${amount}
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