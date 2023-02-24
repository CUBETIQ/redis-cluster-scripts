#!/bin/bash

REDIS_MASTER_NAME="redis-master"
REDIS_PORT=6379
ITERATIONS=1000

# Define a function to execute Redis set and get operations
run_redis_commands() {
  for ((i=1; i<=ITERATIONS; i++))
  do
    # run in multiple threads
    docker exec -it $REDIS_MASTER_NAME redis-cli -c -p $REDIS_PORT set foo$i bar$i
    docker exec -it $REDIS_MASTER_NAME redis-cli -c -p $REDIS_PORT get foo$i > /dev/null
  done
}

echo "Starting Redis set/get benchmark..."

# Measure the time taken to execute the Redis commands
start_time="$(date -u +%s.%N)"
run_redis_commands
end_time="$(date -u +%s.%N)"

echo "Benchmark completed."

# Calculate the total time taken and average time per command
elapsed_time="$(bc <<<"$end_time-$start_time")"
average_time="$(bc <<<"scale=6; $elapsed_time/$ITERATIONS")"

echo "Total time taken: $elapsed_time seconds."
echo "Average time per command: $average_time seconds."
