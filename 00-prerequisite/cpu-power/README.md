# CPU governor

The host boots with the `performance` governor. Under `intel_pstate`, `powersave` still scales up under load; it only stops holding the cores at full clock while idle.

On the host:

```bash
apt update && apt install linux-cpupower
```

Copy [`cpu-powersave.service`](./cpu-powersave.service) to `/etc/systemd/system/`, then:

```bash
systemctl daemon-reload
systemctl enable --now cpu-powersave.service
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor | sort | uniq -c
```

The service is a oneshot, so `systemctl is-active` reports it `inactive` once it has run.
