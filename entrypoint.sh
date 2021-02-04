#!/bin/bash

set -u

function parseInputs(){
	if [ "${INPUT_CDK_SUBCOMMAND}" == "" ]; then
		echo "Input cdk_subcommand cannot be empty"
		exit 1
	fi
}

function installAwsCdk(){
	echo "Installing aws-cdk (ver: ${INPUT_CDK_VERSION})..."
	if [ "${INPUT_CDK_VERSION}" == "latest" ]; then
		if [ "${INPUT_DEBUG_LOG}" == "true" ]; then
			yarn global add aws-cdk
		else
			yarn global add aws-cdk >/dev/null 2>&1
		fi

		if [ "${?}" -ne 0 ]; then
			echo "Failed to install aws-cdk ${INPUT_CDK_VERSION}"
		else
			echo "Successfully installed aws-cdk ${INPUT_CDK_VERSION}"
		fi
	else
		if [ "${INPUT_DEBUG_LOG}" == "true" ]; then
			yarn global add aws-cdk@${INPUT_CDK_VERSION}
		else
			yarn global add aws-cdk@${INPUT_CDK_VERSION} >/dev/null 2>&1
		fi

		if [ "${?}" -ne 0 ]; then
			echo "Failed to install aws-cdk ${INPUT_CDK_VERSION}"
		else
			echo "Successfully installed aws-cdk ${INPUT_CDK_VERSION}"
		fi
	fi
}

function installEsbuild(){
	echo "Installing esbuild..."
	if [ "${INPUT_DEBUG_LOG}" == "true" ]; then
		yarn global add esbuild
	else
		yarn global add esbuild >/dev/null 2>&1
	fi

	if [ "${?}" -ne 0 ]; then
		echo "Failed to install esbuild"
	else
		echo "Successfully installed esbuild"
	fi
}

function runCdk(){
	echo "Run cdk ${INPUT_CDK_SUBCOMMAND} ${INPUT_CDK_ARGS} \"${INPUT_CDK_STACK}\""
	output=$(cdk ${INPUT_CDK_SUBCOMMAND} ${INPUT_CDK_ARGS} "${INPUT_CDK_STACK}" 2>&1)
	exitCode=${?}
	echo ::set-output name=status_code::${exitCode}
	echo "${output}"

	commentStatus="Failed"
	if [ "${exitCode}" == "0" ]; then
		commentStatus="Success"
	elif [ "${exitCode}" != "0" ]; then
		echo "CDK subcommand ${INPUT_CDK_SUBCOMMAND} for stack ${INPUT_CDK_STACK} has failed. See above console output for more details."
		exit 1
	fi

	if [ "$GITHUB_EVENT_NAME" == "pull_request" ] && [ "${INPUT_ACTIONS_COMMENT}" == "true" ]; then
		commentWrapper="#### \`cdk ${INPUT_CDK_SUBCOMMAND}\` ${commentStatus}
<details><summary>Show Output</summary>

\`\`\`
${output}
\`\`\`

</details>

*Workflow: \`${GITHUB_WORKFLOW}\`, Action: \`${GITHUB_ACTION}\`, Working Directory: \`${INPUT_WORKING_DIR}\`*"

		payload=$(echo "${commentWrapper}" | jq -R --slurp '{body: .}')
		commentsURL=$(cat ${GITHUB_EVENT_PATH} | jq -r .pull_request.comments_url)

		echo "${payload}" | curl -s -S -H "Authorization: token ${GITHUB_TOKEN}" --header "Content-Type: application/json" --data @- "${commentsURL}" > /dev/null
	fi
}

function main(){
	parseInputs
	cd ${GITHUB_WORKSPACE}/${INPUT_WORKING_DIR}
	installAwsCdk
	installEsbuild
	runCdk
}

main
