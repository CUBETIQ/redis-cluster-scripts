#!/bin/bash -e

# This script will create a Redis cluster with 1 master and 3 worker nodes
REDIS_CLUSTER_NETWORK_NAME=redis-cluster
REDIS_MASTER_NAME=redis-master
REDIS_WORKER_NAME=redis-worker
REDIS_ROOT_CONFIG=$(pwd)/redis
REDIS_MASTER_PORT=6379
REDIS_WORKER_COUNT=$REDIS_WORKER_COUNT

if [ -z "$REDIS_WORKER_COUNT" ]; then
    REDIS_WORKER_COUNT=6
fi

echo "Redis worker count: $REDIS_WORKER_COUNT"

EXECUTE_ONLY_REMOVE_ALL_CONTAINERS=$EXECUTE_ONLY_REMOVE_ALL_CONTAINERS

# Stop and remove any existing containers
echo "Stopping and removing $REDIS_MASTER_NAME"
docker rm -f $REDIS_MASTER_NAME

for i in $(seq 1 $REDIS_WORKER_COUNT); do
    NAME="${REDIS_WORKER_NAME}-$i"
    echo "Stopping and removing $NAME"
    docker rm -f $NAME
done

if [ "$EXECUTE_ONLY_REMOVE_ALL_CONTAINERS" = true ]; then
    exit 0
fi

# Check docker network exists
echo "Checking docker network exists"
if [ "$(docker network ls | grep $REDIS_CLUSTER_NETWORK_NAME)" ]; then
    # Remove any existing networks
    echo "Removing any existing networks"
    docker network rm  $REDIS_CLUSTER_NETWORK_NAME
else
    echo "Docker network does not exist"
fi

# Create the redis root config directory
if [ ! -d "$REDIS_ROOT_CONFIG" ]; then
    echo "Creating the redis root config directory"
    mkdir -p $REDIS_ROOT_CONFIG

    # Create the redis.conf file
    echo "Creating the redis.conf file"
    touch $REDIS_ROOT_CONFIG/redis.conf

    # Append the config string to the redis.conf file
    echo "Append the config string to the redis.conf file"
    echo "port 6379" >> $REDIS_ROOT_CONFIG/redis.conf
    echo "cluster-enabled yes" >> $REDIS_ROOT_CONFIG/redis.conf
    echo "cluster-config-file nodes.conf" >> $REDIS_ROOT_CONFIG/redis.conf
    echo "cluster-node-timeout 5000" >> $REDIS_ROOT_CONFIG/redis.conf
    echo "appendonly yes" >> $REDIS_ROOT_CONFIG/redis.conf
fi

echo "Load redis root config from: $REDIS_ROOT_CONFIG"
echo "=============================="
cat $REDIS_ROOT_CONFIG/redis.conf
echo "=============================="

# Create a network for the cluster
echo "Creating a network for the cluster"
docker network create $REDIS_CLUSTER_NETWORK_NAME

# Start the master node
echo "Starting the master node"
docker run --name $REDIS_MASTER_NAME --net $REDIS_CLUSTER_NETWORK_NAME -p $REDIS_MASTER_PORT:6379 -d redis redis-server --appendonly yes

# Start the worker nodes
echo "Starting the worker nodes"
for i in $(seq 1 $REDIS_WORKER_COUNT); do
    NAME="${REDIS_WORKER_NAME}-$i"
    echo "Starting $NAME"
    docker run --name $NAME --net $REDIS_CLUSTER_NETWORK_NAME \
        -v $REDIS_ROOT_CONFIG:/usr/local/etc/redis \
        -d redis redis-server /usr/local/etc/redis/redis.conf
done

# Get the IP addresses of the worker nodes and assign them to variables
echo "Getting the IP addresses of the worker nodes"
for i in $(seq 1 $REDIS_WORKER_COUNT); do
    NAME="${REDIS_WORKER_NAME}-$i"
    IP_VAR="REDIS_WORKER_IP_$i"
    eval $IP_VAR=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $NAME)
    echo "IP address of $NAME is ${!IP_VAR}"
done

# Join the cluster nodes
echo "Joining the cluster nodes"
redis_nodes=""
for i in $(seq 1 $REDIS_WORKER_COUNT); do
    IP_NODE="REDIS_WORKER_IP_$i"
    redis_nodes="$redis_nodes ${!IP_NODE}:6379"
done
echo "Redis worker nodes: $redis_nodes"
docker exec -it $REDIS_MASTER_NAME redis-cli --cluster create $redis_nodes --cluster-replicas 1 --cluster-yes

# Test the cluster
echo "Testing the cluster"
docker exec -it $REDIS_MASTER_NAME redis-cli -c -p 6379 set foo bar
docker exec -it $REDIS_MASTER_NAME redis-cli -c -p 6379 get foo

echo "Done"