# AIassistedDevop

## VM health check script

Run:

```bash
./vm_health_check.sh
```

Optional explain mode:

```bash
./vm_health_check.sh explain
```

Health is `healthy` only when CPU, memory, and disk utilization are each below 60%; otherwise it is `unhealthy`.
