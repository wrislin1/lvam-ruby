#!/bin/bash

# Check if two arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <environment> <service>"
    echo "Environment are staging and prod"
    echo "Services are app, jobs, or immediate"
    exit 1
fi

# Store the provided arguments in variables
environment=$1
service=$2

# Define the command based on the values of environment and service
if [ "$environment" == "prod" ]; then
    if [ "$service" == "app" ]; then
        AWS_PROFILE=lvam aws logs tail /ecs/lvam-prod --follow --region=us-west-2
    elif [ "$service" == "jobs" ]; then
        AWS_PROFILE=lvam aws logs tail /ecs/lvam-prod-wordker --follow --region=us-west-2
    else
        echo "Invalid service: $service"
        exit 1
    fi
elif [ "$environment" == "staging" ]; then
    if [ "$service" == "app" ]; then
        AWS_PROFILE=lvam aws logs tail /ecs/lvam-staging --follow --region=us-west-2
    elif [ "$service" == "jobs" ]; then
        AWS_PROFILE=lvam aws logs tail /ecs/lvam-staging-jobs --follow --region=us-west-2
    else
        echo "Invalid service: $service"
        exit 1
    fi
else
    echo "Invalid environment: $environment"
    exit 1
fi

# Execute the selected command
echo "Executing command: $command"
# Uncomment the following line to execute the command
# $command