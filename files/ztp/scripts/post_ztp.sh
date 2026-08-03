#!/bin/sh

TEST_TIME=$(date +%Y%m%d_%H%M%S)
RESULT_DIR="/host/ztp-test/$TEST_TIME"

mkdir -p "$RESULT_DIR" || exit 1

echo "ZTP post-provisioning script ran at $(date)" \
  > "$RESULT_DIR/ztp_post_script_ran.txt"

sonic-installer list \
  > "$RESULT_DIR/ztp_sonic_installer_list.txt" 2>&1 || true

show version \
  > "$RESULT_DIR/ztp_show_version.txt" 2>&1 || true

echo "Results saved in: $RESULT_DIR" \
  > "$RESULT_DIR/result_location.txt"

sync
exit 0


