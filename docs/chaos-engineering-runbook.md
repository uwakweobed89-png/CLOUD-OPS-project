# Chaos Engineering Runbook — CloudOps Platform

## Overview
This runbook documents the chaos engineering experiments
designed for the CloudOps Production Platform using
AWS Fault Injection Simulator (FIS).

## Experiment 1 — ECS Task Termination

### Hypothesis
If one ECS task is terminated, ECS Auto Scaling will
detect the failure and replace it within 60 seconds
maintaining service availability.

### Method
- Tool: AWS FIS
- Action: aws:ecs:stop-task
- Target: 1 task in cloudops-cluster
- Duration: 2 minutes

### Expected Results
- Running tasks drops from 2 to 1
- ECS detects task count below desired count
- New task starts within 60 seconds
- CloudWatch alarm ECS-Low-Running-Tasks fires
- SNS sends email alert to uwakweobed89@gmail.com
- Service returns to 2/2 running tasks

### Recovery Time Objective (RTO)
Target: < 60 seconds
Measured: TBD

### Rollback Plan
If service doesn't recover automatically:
aws ecs update-service --cluster cloudops-cluster
--service cloudops-api-service --desired-count 2

## Experiment 2 — AZ Failure Simulation

### Hypothesis  
If all tasks in AZ1 are terminated, tasks in AZ2
continue serving traffic with zero downtime.

### Method
- Tool: AWS FIS
- Action: aws:ecs:stop-task
- Target: all tasks in us-east-1a
- Duration: 5 minutes

### Expected Results
- Traffic served entirely from AZ2
- No user-facing errors
- Auto Scaling adds tasks in AZ2
- Recovery within 120 seconds

## Experiment 3 — CPU Stress Test

### Hypothesis
When CPU exceeds 70%, Auto Scaling adds containers
within 3 minutes to handle the load.

### Method
- Tool: AWS FIS  
- Action: aws:ssm:send-command (stress-ng)
- Target: ECS task CPU
- Duration: 10 minutes
- CPU Target: 90%

### Expected Results
- CPU alarm fires within 5 minutes
- Auto Scaling adds containers
- CPU drops below 70% threshold
- Scale-in happens after 120s cooldown

## Results Documentation

| Experiment | Date | Result | RTO | Notes |
|---|---|---|---|---|
| Task termination | TBD | TBD | TBD | Pending FIS access |
| AZ failure | TBD | TBD | TBD | Pending FIS access |
| CPU stress | TBD | TBD | TBD | Pending FIS access |

## Lessons Learned
- Multi-AZ deployment critical for HA
- Auto Scaling cooldown periods affect RTO
- CloudWatch alarms provide early warning
