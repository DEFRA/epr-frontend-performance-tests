#!/bin/sh
set -x

echo "run_id: $RUN_ID in $ENVIRONMENT"

# Best-effort cleanup of every orgId the test suite created. Runs regardless
# of pass/fail — we still want to delete data from failed runs. See PAE-1194.
cleanup_created_orgs() {
  id_file="/opt/perftest/test-artifacts/created-org-ids.txt"
  if [ ! -s "$id_file" ]; then
    echo "cleanup: no IDs to clean up"
    return 0
  fi
  if [ -z "$ENVIRONMENT" ]; then
    echo "cleanup: ENVIRONMENT not set; skipping"
    return 0
  fi
  backend_url="https://epr-backend.${ENVIRONMENT}.cdp-int.defra.cloud"
  total=$(wc -l < "$id_file" | tr -d ' ')
  echo "cleanup: deleting $total orgs via $backend_url"
  fail=0
  while IFS= read -r id; do
    [ -z "$id" ] && continue
    status=$(curl -sS -o /dev/null -w '%{http_code}' \
      -X DELETE "$backend_url/v1/dev/organisations/$id" || echo "000")
    echo "  cleanup: $id -> $status"
    [ "$status" = "200" ] || fail=$((fail + 1))
  done < "$id_file"
  echo "cleanup: complete. failures: $fail / $total"
  return 0
}

trap 'cleanup_created_orgs' EXIT

NOW=$(date +"%Y%m%d-%H%M%S")

if [ -z "${JM_HOME}" ]; then
  JM_HOME=/opt/perftest
fi

JM_SCENARIOS=${JM_HOME}/scenarios
JM_REPORTS=${JM_HOME}/reports
JM_LOGS=${JM_HOME}/logs

mkdir -p ${JM_REPORTS} ${JM_LOGS}

TEST_SCENARIO=${TEST_SCENARIO:-test}
SCENARIOFILE=${JM_SCENARIOS}/${TEST_SCENARIO}.jmx
REPORTFILE=${NOW}-perftest-${TEST_SCENARIO}-report.csv
LOGFILE=${JM_LOGS}/perftest-${TEST_SCENARIO}.log

# Before running the suite, replace 'service-name' with the name/url of the service to test.
# ENVIRONMENT is set to the name of th environment the test is running in.
SERVICE_ENDPOINT=${SERVICE_ENDPOINT:-service-name.${ENVIRONMENT}.cdp-int.defra.cloud}
# PORT is used to set the port of this performance test container
SERVICE_PORT=${SERVICE_PORT:-443}
SERVICE_URL_SCHEME=${SERVICE_URL_SCHEME:-https}

# Run the test suite
jmeter -n -t ${SCENARIOFILE} -e -l "${REPORTFILE}" -o ${JM_REPORTS} -j ${LOGFILE} -f \
-Jenv="${ENVIRONMENT}" \
-Jdomain="${SERVICE_ENDPOINT}" \
-Jport="${SERVICE_PORT}" \
-Jprotocol="${SERVICE_URL_SCHEME}"

# Publish the results into S3 so they can be displayed in the CDP Portal
if [ -n "$RESULTS_OUTPUT_S3_PATH" ]; then
  # Copy the CSV report file and the generated report files to the S3 bucket
   if [ -f "$JM_REPORTS/index.html" ]; then
      aws --endpoint-url=$S3_ENDPOINT s3 cp "$REPORTFILE" "$RESULTS_OUTPUT_S3_PATH/$REPORTFILE"
      aws --endpoint-url=$S3_ENDPOINT s3 cp "$JM_REPORTS" "$RESULTS_OUTPUT_S3_PATH" --recursive
      if [ $? -eq 0 ]; then
        echo "CSV report file and test results published to $RESULTS_OUTPUT_S3_PATH"
      fi
   else
      echo "$JM_REPORTS/index.html is not found"
      exit 1
   fi
else
   echo "RESULTS_OUTPUT_S3_PATH is not set"
   exit 1
fi

exit $test_exit_code
