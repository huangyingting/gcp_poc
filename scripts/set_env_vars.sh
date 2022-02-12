#!/bin/bash
# Replace [YOUR-ORGANIZATION-NAME] in the command below with your organization
# name.
TF_VAR_org_id=$(gcloud organizations list \
  --filter="display_name=gcp.cnpro.org" \
  --format="value(ID)")
export TF_VAR_org_id


TF_VAR_region1=us-west1
export TF_VAR_region1

TF_VAR_zone1=us-west1-b
export TF_VAR_zone1

TF_VAR_region2=europe-west1
export TF_VAR_region2

TF_VAR_zone2=europe-west1-b
export TF_VAR_zone2

TF_VAR_user_account=$(gcloud auth list \
  --filter=status:ACTIVE \
  --format="value(account)")
export TF_VAR_user_account

TF_VAR_billing_account=$(gcloud alpha billing accounts list \
  | grep True \
  | awk '{print $1}')
export TF_VAR_billing_account

TF_VAR_vpc_pid=$(echo gcp-poc-$(od -An -N3 -D /dev/random) \
  | sed 's/ //')
export TF_VAR_vpc_pid

env | grep TF_ > TF_ENV_VARS 
