---
id: "0015"
title: geo-db backs up to R2 weekly, with two weeks kept
date: 2026-11-18
status: accepted
tags: [cloudnative-pg, backup, r2, barman]
---

# geo-db backs up to R2 weekly, with two weeks kept

`geo-db` (0013) holds public reference data: zoning, FEMA flood and USGS water maps
and the parcels and roads of five counties. 0014 left it without a backup because it
can be copied again. In practice a full copy takes hours and the public servers it
comes from refuse or time out for whole afternoons, so losing the volume would cost a
day. It is backed up the way appraisal-db is, through the Barman Cloud plugin into the
same bucket and prefix with the same key pair, but with its own ObjectStore `r2-geo`:
a base backup on Sundays at 05:00 and 14 days kept. About 1.5 GB.

## Rejected

- **No backup (0014).** Cheap only while the copies are quick and the servers answer.
- **A daily base backup and 30 days, as appraisal-db.** The data changes a few times a
  year; the extra copies would hold the same rows.
- **pg_dump to R2 by a CronJob.** A second mechanism beside the plugin the lab already runs.
