#!/bin/sh
# Run plan-expiry update every 5 minutes (no cron, avoids setpgid in container)
INTERVAL=300
while true; do
  psql -c 'UPDATE users SET "planId" = 1 WHERE "planExpiresAt" IS NOT NULL AND "planExpiresAt" < NOW() AND "planId" != 1;'
  sleep "$INTERVAL"
done
