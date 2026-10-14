# Runtime payload

This service does not commit the OpenBao server binary. The runtime payload is
acquired at package time from the pinned upstream `openbao/openbao` release and
staged into the release artifact:

```
openbao-<platform>/
  runtime/
    bao(.exe)        # pinned upstream OpenBao server binary
  config/
    example.env      # deploy-local env inputs
```

The server configuration (`runtime/openbao.hcl`) is materialized by the Service
Lasso `config` action from the `config.files` block in `service.json`, which
resolves `${SERVICE_PORT}` for the deployment.

Run `scripts/package.ps1` (Windows) or `scripts/package.sh` (Linux/macOS) to
produce the platform artifact under `dist/`.
