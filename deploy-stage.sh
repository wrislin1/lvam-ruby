#!/bin/bash

set -x
set -e
if [ ! -f config/credentials/staging.key ]
then
    AWS_PROFILE=lvam aws s3 cp s3://lvam-config-secure/staging.key config/credentials
else
    echo "Staging key present, not updating from S3."
fi

AWS_PROFILE=lvam aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 033804452824.dkr.ecr.us-west-2.amazonaws.com
[[ -e Dockerfile ]] && cp Dockerfile Dockerfile.bkp
cp staging.Dockerfile Dockerfile
docker build -t lvam-staging .

docker tag lvam-staging 033804452824.dkr.ecr.us-west-2.amazonaws.com/lvam-staging

RAILS_ENV=staging bundle install --jobs 20
RAILS_ENV=staging bundle exec rake assets:clean
RAILS_ENV=staging bundle exec rake assets:clobber
RAILS_ENV=staging bundle exec rake assets:precompile
RAILS_ENV=staging bundle exec rake assets:sync

docker push 033804452824.dkr.ecr.us-west-2.amazonaws.com/lvam-staging

[[ -e Dockerfile.bkp ]] && cp Dockerfile.bkp Dockerfile

AWS_REGION=us-west-2 AWS_PROFILE=lvam aws ecs update-service --service "lvam-staging1" --cluster "lvam" --force-new-deployment --no-cli-pager
AWS_REGION=us-west-2 AWS_PROFILE=lvam aws ecs update-service --service "lvam-staging-worker" --cluster "lvam" --force-new-deployment --no-cli-pager