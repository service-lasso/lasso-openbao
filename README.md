# lasso-openbao

_Status: service repo bootstrapped from [`service-lasso/service-template`](https://github.com/service-lasso/service-template)_

`lasso-openbao` packages the [OpenBao](https://openbao.org) secrets manager as a
Service Lasso service.

- Service id: `@openbao`
- Pinned upstream runtime: `openbao/openbao` `v2.7.1`
- Default API port: `18200`, cluster port: `18201`

This repo was created from the canonical Service Lasso template and adapts the
template contract to OpenBao. The upstream server binary is not committed; it is
acquired at package time from the pinned upstream release.

## Layout

- `service.json` - canonical `@openbao` service manifest
- `verify/service-harness.json` - harness validation contract
- `scripts/package.*` - acquire the pinned upstream binary and build the release artifact
- `scripts/test.*` - prove service identity and runtime version
- `scripts/verify.*` - thin wrappers around the released `service-lasso-harness`
- `runtime/` - runtime payload notes (binary is acquired, not committed)
- `config/example.env` - deploy-local, non-secret env inputs
- `services/@openbao/service.json` - example managed-service inventory entry

## Quick start

### Package

```powershell
pwsh -NoLogo -NoProfile -File .\scripts\package.ps1
```

POSIX:

```sh
bash ./scripts/package.sh
```

### Tests

Run packaging first so the pinned runtime is present under `dist/`.

```powershell
pwsh -NoLogo -NoProfile -File .\scripts\test.ps1
```

POSIX:

```sh
bash ./scripts/test.sh
```

### Harness verification

Install the released `service-lasso-harness` binary (or set
`SERVICE_LASSO_HARNESS_BIN`), then run:

```powershell
pwsh -NoLogo -NoProfile -File .\scripts\verify.ps1
```

## Runtime model

`service.json` declares the `@openbao` run contract:

- `artifact.platforms.<platform>.command` runs the pinned `bao` server binary.
- The `config` action materializes `runtime/openbao.hcl` with the resolved
  service port. The server uses PebbleDB storage and a loopback TCP listener.
- `healthcheck.type` is `tcp`, because a freshly started OpenBao node responds
  `501` on `/v1/sys/health` until it is initialized and unsealed.

## Upstream version pin

The upstream version is pinned in both `scripts/package.*` and
`service.json` (`version`). Keep them in sync when upgrading OpenBao.
