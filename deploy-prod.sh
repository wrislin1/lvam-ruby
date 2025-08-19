#!/bin/bash

set -x
set -e
if [ ! -f config/credentials/production.key ]
then
    AWS_PROFILE=lvam aws s3 cp s3://lvam-config-secure/production.key config/credentials
else
    echo "Production key present, not updating from S3."
fi

AWS_PROFILE=lvam aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 033804452824.dkr.ecr.us-west-2.amazonaws.com
[[ -e Dockerfile ]] && cp Dockerfile Dockerfile.bkp
cp production.Dockerfile Dockerfile
docker build -t lvam-prod .

docker tag lvam-prod 033804452824.dkr.ecr.us-west-2.amazonaws.com/lvam-prod

RAILS_ENV=production bundle install --jobs 20
RAILS_ENV=production bundle exec rake assets:precompile
RAILS_ENV=production bundle exec rake assets:sync

docker push 033804452824.dkr.ecr.us-west-2.amazonaws.com/lvam-prod

[[ -e Dockerfile.bkp ]] && cp Dockerfile.bkp Dockerfile

AWS_REGION=us-west-2 AWS_PROFILE=lvam aws ecs update-service --service "lvam-prod" --cluster "lvam" --force-new-deployment --no-cli-pager
AWS_REGION=us-west-2 AWS_PROFILE=lvam aws ecs update-service --service "lvam-prod-worker" --cluster "lvam" --force-new-deployment --no-cli-pager