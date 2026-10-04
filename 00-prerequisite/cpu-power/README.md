# CPU governor and EPP

The host boots with the `performance` governor. Under `intel_pstate`, `powersave` still scales up under load; it only stops holding the cores at full clock while idle.

How eagerly it boosts is the energy-performance preference (EPP), `balance_performance` by default. The service sets it to `balance_power`. Measured on 2026-10-04 with the lab running, a minute each:

| EPP | Package | Clock | Power |
|---|---|---|---|
| `balance_performance` | 61 °C | 1297 MHz | 13 W |
| `balance_power` | 56 °C | 1046 MHz | 9 W |
| `power` | 55 °C | 1021 MHz | 8 W |

`power` saves another watt and caps the boost under real load, so the service stops at `balance_power`.

On the host:

```bash
apt update && apt install linux-cpupower
```

Copy [`cpu-powersave.service`](./cpu-powersave.service) to `/etc/systemd/system/`, then:

```bash
systemctl daemon-reload
systemctl enable --now cpu-powersave.service
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor | sort | uniq -c
cat /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference | sort | uniq -c
```

The service is a oneshot, so `systemctl is-active` reports it `inactive` once it has run.
