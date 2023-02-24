# Redis Cluter and Configuration

-   Redis master
-   Redis workers (default: 6)

### Usage for `Bash Script`

-   Run and start cluster

```shell
make
```

-   Custom cluster workers (use 16 workers)

```shell
 REDIS_WORKER_COUNT=16 make
```

-   Clean up the containers

```shell
make clean
```

-   Custom clean cluster workers (use 16 workers)

```shell
 REDIS_WORKER_COUNT=16 make clean
```

### Contributors

-   Sambo Chea <sombochea@cubetiqs.com>
