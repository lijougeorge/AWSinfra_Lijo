#!/bin/bash
set -e

ACTION=$1
MODULE_DIR=$2
ACCOUNT_ID=$3
REGION=$4
ENVIRONMENT=${5:-dev}

S3_BUCKET="teraform-tfstate-bucket-${ACCOUNT_ID}"

run_terraform() {
    local MODULE=$1
    local TARGET_DIR="modules/$MODULE"
    local STATE_KEY="$ENVIRONMENT/$MODULE/terraform.tfstate"
    local TFVARS_FILE="$TARGET_DIR/terraform.tfvars.json"

    echo "------------------------------------------"
    echo "Running Terraform in directory: $TARGET_DIR"
    echo "Environment: $ENVIRONMENT"
    echo "State Key: $STATE_KEY"

    if [[ ! -f "$TFVARS_FILE" ]]; then
        echo "⚠️  Skipping module '$MODULE': $TFVARS_FILE not found."
        return
    fi

    terraform -chdir="$TARGET_DIR" init \
        -backend-config="bucket=$S3_BUCKET" \
        -backend-config="key=$STATE_KEY" \
        -backend-config="region=$REGION" \
        -backend-config="encrypt=true"

    export TF_VAR_environment=$ENVIRONMENT

    if [[ "$ACTION" == "plan" ]]; then
        echo "Planning Terraform deployment for module: $MODULE..."
        terraform -chdir="$TARGET_DIR" plan -var-file="terraform.tfvars.json" -out=tfplan

        cp "$TARGET_DIR/tfplan" ./tfplan
        terraform -chdir="$TARGET_DIR" show tfplan > tfplan.txt
        terraform -chdir="$TARGET_DIR" show -json tfplan > tfplan.json

        echo "Generating CSV from tfplan.json..."
        jq -r '
            .resource_changes[] |
            select(.change.actions != null) |
            [
                .address,
                .type,
                .name,
                (.change.actions | join("/"))
            ] | @csv
        ' tfplan.json > tfplan.csv

    elif [[ "$ACTION" == "apply" ]]; then
        echo "Applying Terraform changes for module: $MODULE..."
        terraform -chdir="$TARGET_DIR" apply -var-file="terraform.tfvars.json" -auto-approve

    elif [[ "$ACTION" == "destroy" ]]; then
        echo "Destroying Terraform resources for module: $MODULE..."
        terraform -chdir="$TARGET_DIR" destroy -var-file="terraform.tfvars.json" -auto-approve

    else
        echo "❌ Invalid action: $ACTION"
        exit 1
    fi
}

if [[ "$MODULE_DIR" == "all" ]]; then
    for MODULE in $(ls modules); do
        run_terraform "$MODULE"
    done
else
    if [[ ! -d "modules/$MODULE_DIR" ]]; then
        echo "❌ Error: Module directory 'modules/$MODULE_DIR' does not exist."
        exit 1
    fi
    run_terraform "$MODULE_DIR"
fi

echo "✅ Terraform operation ($ACTION) completed."
