#!/usr/bin bash

#aws iot describe-endpoint
export DEPLOYMENT_BUCKET=mangdang2023

##### no need to change anything below
export DANCE_FILE=demo.py
export IOT_ENDPOINT=`aws iot describe-endpoint | grep amazon | cut -d: -f 2 | sed 's/\"//g'` 
cd ~/environment/mini-pupper-aws
aws s3 cp greengrass/docker-compose.yaml s3://${DEPLOYMENT_BUCKET}/artifacts/docker-compose.yaml
aws s3 sync ~/environment/mini-pupper-aws/robot_ws/src/mini_pupper_dance/routines s3://${DEPLOYMENT_BUCKET}/artifacts/routines
IOT_CONFIG_FILE=greengrass/aws_iot_params.yaml
cat ${IOT_CONFIG_FILE}.template | sed -e "s/IOT_ENDPOINT_PLACEHOLDER/${IOT_ENDPOINT}/g" > ${IOT_CONFIG_FILE}
cd ~/environment/mini-pupper-aws
aws s3 cp greengrass/aws_iot_params.yaml s3://${DEPLOYMENT_BUCKET}/artifacts/aws_iot_params.yaml
RECIPE_CONFIG_FILE=greengrass/recipe.yaml
cat ${RECIPE_CONFIG_FILE}.template | sed -e "s/S3_BUCKET_PLACEHOLDER/${DEPLOYMENT_BUCKET}/g"     -e "s/DANCE_ROUTINE_PLACEHOLDER/${DANCE_FILE}/g" > ${RECIPE_CONFIG_FILE}
aws greengrassv2 create-component-version     --inline-recipe fileb://greengrass/recipe.yaml
