run:
	./redis-cluster.sh

clean:
	EXECUTE_ONLY_REMOVE_ALL_CONTAINERS=true ./redis-cluster.sh