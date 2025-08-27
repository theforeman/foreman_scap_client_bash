#!/usr/bin/env bash

set -eo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Path to the binary and test config
BINARY="$PROJECT_ROOT/bin/foreman_scap_client"
TEST_CONFIG="$SCRIPT_DIR/fixtures/$1"

# Function to print test results
print_test_result() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    local result="$4"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        echo -e "  Expected: ${YELLOW}$expected${NC}"
        echo -e "  Actual:   ${YELLOW}$actual${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

echo "=== Testing foreman_scap_client YAML Configuration Parser ==="
echo "Using config file: $TEST_CONFIG"
echo

# Create a temporary file with functions only (exclude main entry)
TEMP_FUNCTIONS=$(mktemp)
# Get everything up to but not including main entry
limit=$(grep -n "# MAIN ENTRY" "$BINARY" | cut -d: -f1)
head -n "$limit" "$BINARY" > "$TEMP_FUNCTIONS"

echo "Sourcing functions from binary..."
# shellcheck source=/dev/null
source "$TEMP_FUNCTIONS"
rm -f "$TEMP_FUNCTIONS"

echo "Testing policy 1 configuration..."

# Set policy ID and call load_config directly
export POLICY_ID="1"
if load_config "$TEST_CONFIG"; then
    echo "✓ Policy 1 config loaded successfully"

    # Test server configuration
    expected="foreman_proxy.example.com"
    actual="$SERVER"
    [ "$actual" = "$expected" ] && result="PASS" || result="FAIL"
    print_test_result "Server parsing" "$expected" "$actual" "$result"

    # Test port configuration
    expected="8443"
    actual="$PORT"
    [ "$actual" = "$expected" ] && result="PASS" || result="FAIL"
    print_test_result "Port parsing" "$expected" "$actual" "$result"

    # Test timeout configuration
    expected="60"
    actual="$TIMEOUT"
    [ "$actual" = "$expected" ] && result="PASS" || result="FAIL"
    print_test_result "Timeout parsing" "$expected" "$actual" "$result"

    # Test fetch_remote_resources configuration
    expected="true"
    actual="$FETCH_REMOTE_RESOURCES"
    [ "$actual" = "$expected" ] && result="PASS" || result="FAIL"
    print_test_result "Fetch remote resources parsing" "$expected" "$actual" "$result"

    # Test HTTP proxy settings
    expected="foreman_http_proxy.example.com"
    actual="$HTTP_PROXY_SERVER"
    [ "$actual" = "$expected" ] && result="PASS" || result="FAIL"
    print_test_result "HTTP proxy server parsing" "$expected" "$actual" "$result"

    expected="8080"
    actual="$HTTP_PROXY_PORT"
    [ "$actual" = "$expected" ] && result="PASS" || result="FAIL"
    print_test_result "HTTP proxy port parsing" "$expected" "$actual" "$result"

    # Test CA file configuration
    expected="/var/lib/puppet/ssl/certs/ca.pem"
    actual="$CA_FILE"
    [ "$actual" = "$expected" ] && result="PASS" || result="FAIL"
    print_test_result "CA file parsing" "$expected" "$actual" "$result"

    # Test host certificate configuration
    expected="/var/lib/puppet/ssl/certs/client.example.com.pem"
    actual="$HOST_CERTIFICATE"
    [ "$actual" = "$expected" ] && result="PASS" || result="FAIL"
    print_test_result "Host certificate parsing" "$expected" "$actual" "$result"

    # Test host private key configuration
    expected="/var/lib/puppet/ssl/private_keys/client.example.com.pem"
    actual="$HOST_PRIVATE_KEY"
    [ "$actual" = "$expected" ] && result="PASS" || result="FAIL"
    print_test_result "Host private key parsing" "$expected" "$actual" "$result"

    # Test ciphers configuration (should have brackets and quotes removed)
    expected="AES256-SHA:AES128-SHA:DES-CBC3-SHA"
    actual="$CIPHERS"
    [ "$actual" = "$expected" ] && result="PASS" || result="FAIL"
    print_test_result "Ciphers parsing and formatting" "$expected" "$actual" "$result"

    # Test policy 1 profile (should be empty)
    expected=""
    actual="$POLICY_PROFILE"
    [ "$actual" = "$expected" ] && result="PASS" || result="FAIL"
    print_test_result "Policy 1 profile parsing (empty)" "$expected" "$actual" "$result"

    # Test policy 1 content path
    expected="/usr/share/xml/scap/ssg/content/ssg-fedora-ds.xml"
    actual="$POLICY_CONTENT_PATH"
    [ "$actual" = "$expected" ] && result="PASS" || result="FAIL"
    print_test_result "Policy 1 content path parsing" "$expected" "$actual" "$result"

    # Test policy 1 download path (with space)
    expected="d test1"
    actual="$POLICY_DOWNLOAD_PATH"
    [ "$actual" = "$expected" ] && result="PASS" || result="FAIL"
    print_test_result "Policy 1 download path parsing (with space)" "$expected" "$actual" "$result"

    # Test policy 1 tailoring path (should be empty as it's commented)
    expected=""
    actual="$POLICY_TAILORING_PATH"
    [ "$actual" = "$expected" ] && result="PASS" || result="FAIL"
    print_test_result "Policy 1 tailoring path parsing (commented)" "$expected" "$actual" "$result"
else
    echo "✗ Failed to load policy 1 config"
    exit 1
fi

echo
echo "Testing policy 2 configuration..."

# Test policy 2
export POLICY_ID="2"
if load_config "$TEST_CONFIG"; then
    echo "✓ Policy 2 config loaded successfully"

    # Test policy 2 profile
    expected="xccdf_org.ssgproject.content_profile_common"
    actual="$POLICY_PROFILE"
    [ "$actual" = "$expected" ] && result="PASS" || result="FAIL"
    print_test_result "Policy 2 profile parsing" "$expected" "$actual" "$result"

    # Test policy 2 content path
    expected="/usr/share/xml/scap/ssg/content/ssg-fedora-ds.xml"
    actual="$POLICY_CONTENT_PATH"
    [ "$actual" = "$expected" ] && result="PASS" || result="FAIL"
    print_test_result "Policy 2 content path parsing" "$expected" "$actual" "$result"

    # Test policy 2 download path (single quoted)
    expected="dtest2"
    actual="$POLICY_DOWNLOAD_PATH"
    [ "$actual" = "$expected" ] && result="PASS" || result="FAIL"
    print_test_result "Policy 2 download path parsing (single quoted)" "$expected" "$actual" "$result"

    # Test policy 2 tailoring path (double quoted)
    expected="ttest2"
    actual="$POLICY_TAILORING_PATH"
    [ "$actual" = "$expected" ] && result="PASS" || result="FAIL"
    print_test_result "Policy 2 tailoring path parsing (double quoted)" "$expected" "$actual" "$result"

    # Test policy 2 tailoring download path (with space)
    expected="td test2"
    actual="$POLICY_TAILORING_DOWNLOAD_PATH"
    [ "$actual" = "$expected" ] && result="PASS" || result="FAIL"
    print_test_result "Policy 2 tailoring download path parsing (with space)" "$expected" "$actual" "$result"
else
    echo "✗ Failed to load policy 2 config"
    exit 1
fi

echo
echo "Testing non-existent policy (should fail)..."

# Test non-existent policy 3 (in a subshell to avoid exit)
export POLICY_ID="3"
config_result=0
(load_config "$TEST_CONFIG" >/dev/null 2>&1) || config_result=$?

if [ $config_result -eq 0 ]; then
    print_test_result "Non-existent policy 3 handling" "should fail" "passed unexpectedly" "FAIL"
else
    print_test_result "Non-existent policy 3 handling" "should fail" "failed correctly" "PASS"
fi

echo
echo "=== Test Summary ==="
echo -e "Total tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed! ✓${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed! ✗${NC}"
    exit 1
fi
