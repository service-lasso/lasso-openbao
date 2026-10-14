# Changelog

## 0.1.0
- initial starter skeleton for `service-template`
- sample echo service manifest, runtime payloads, verify scripts, packaging scripts, and harness contract

## 2.7.1
- bootstrap `@openbao`: adapt the Service Lasso template contract to the OpenBao secrets manager
- package the pinned upstream `openbao/openbao` `v2.7.1` server binary (win32/linux/darwin)
- add OpenBao server config materialization, ports, URLs, and tcp healthcheck
- rewrite package/test/verify scripts, harness contract, workflows, and docs for `@openbao`
