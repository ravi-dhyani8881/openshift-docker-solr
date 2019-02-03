#!/bin/bash

USER_ID="$(id -u)"
SCRIPT_DIR=$(dirname $0)
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"
TEMPLATE_DIR="${SCRIPT_DIR}/templates"

export MSYS_NO_PATHCONV=1
# ==============================================================================
# Script for setting up the deployment environment in OpenShift
#
# * Requires the OpenShift Origin CLI
# ------------------------------------------------------------------------------
# Usage on Windows:
#  ./generateDeployments.sh [project_namespace] [deployment_env_name] [build_env_name]
#
# Example:
#  ./generateDeployments.sh solr latest solr
# ------------------------------------------------------------------------------
# ToDo:
# * Add support for create or update.
# -----------------------------------------------------------------------------------
#DEBUG_MESSAGES=1
# -----------------------------------------------------------------------------------
PROJECT_NAMESPACE="${1}"
DEPLOYMENT_ENV_NAME="${2}"
BUILD_ENV_NAME="${3}"
# -----------------------------------------------------------------------------------
if [ -z "$PROJECT_NAMESPACE" ]; then
	echo "You must supply PROJECT_NAMESPACE."
	echo -n "Please enter the root namespace of the project; for example 'solr': "
	read PROJECT_NAMESPACE
	PROJECT_NAMESPACE="$(echo "${PROJECT_NAMESPACE}" | tr '[:upper:]' '[:lower:]')"
	echo
fi

if [ -z "$DEPLOYMENT_ENV_NAME" ]; then
	DEPLOYMENT_ENV_NAME="latest"
	echo "Defaulting 'DEPLOYMENT_ENV_NAME' to ${DEPLOYMENT_ENV_NAME} ..."
	echo
fi

if [ -z "$BUILD_ENV_NAME" ]; then
	BUILD_ENV_NAME="solr"
	echo "Defaulting 'BUILD_ENV_NAME' to ${BUILD_ENV_NAME} ..."
	echo
fi

if [ ! -z "$MissingParam" ]; then
	echo "============================================"
	echo "One or more parameters are missing!"
	echo "--------------------------------------------"
	echo "PROJECT_NAMESPACE[{1}]: ${1}"
	echo "DEPLOYMENT_ENV_NAME[{2}]: ${2}"
	echo "BUILD_ENV_NAME[{3}]: ${3}"
	echo "============================================"
	echo
	exit 1
fi
# -------------------------------------------------------------------------------------
DeploymentConfigPostfix="_DeploymentConfig.json"
SOLR_DEPLOYMENT_NAME="solr"
# ==============================================================================

echo "============================================================================="
echo "Switching to project ${PROJECT_NAMESPACE} ..."
echo "-----------------------------------------------------------------------------"
oc project ${PROJECT_NAMESPACE}
echo "============================================================================"
echo

echo "============================================================================="
echo "Deleting previous deployment configuration files ..."
echo "-----------------------------------------------------------------------------"
for file in *${DeploymentConfigPostfix}; do
	echo "Deleting ${file} ..."
	rm -rf ${file};
done
echo "============================================================================="
echo

echo "============================================================================="
echo "Generating deployment configuration for ${SOLR_DEPLOYMENT_NAME} ..."
echo "-----------------------------------------------------------------------------"
${SCRIPTS_DIR}/configureSolrDeployment.sh \
	${SOLR_DEPLOYMENT_NAME} \
	${DEPLOYMENT_ENV_NAME} \
	${BUILD_ENV_NAME} \
	"" \
	"${TEMPLATE_DIR}/${SOLR_DEPLOYMENT_NAME}-deploy.json"

echo "============================================================================="
echo

echo "============================================================================="
echo "Creating deployment configurations in OpenShift project; ${PROJECT_NAMESPACE} ..."
echo "-----------------------------------------------------------------------------"
for file in *${DeploymentConfigPostfix}; do
	echo "Loading ${file} ...";
	oc create -f ${file};
	echo;
done
echo "============================================================================="
echo
