# Initial container security gate and remediation

The first hosted runs for commit `8fdc4e970d759eac156516101c33e64b5cf6f065` were blocked by the container security gates. The final-project scan reported 44 HIGH and zero CRITICAL findings in the Debian-based `python:3.12-slim` runtime, including util-linux, ncurses, libacl, systemd and perl packages. The report showed no Debian fixed version for those findings. The attached failure logs are the actual GitHub Actions output, not an example transcript.

The application uses only Python's standard library. Its runtime was changed to `python:3.12-alpine`, followed by `apk upgrade --no-cache` during the build, to avoid unused Debian utilities and obtain Alpine package updates. The final-project build now explicitly refreshes its base image with `--pull`, matching the DevSecOps build.

Both image gates still block every HIGH and CRITICAL finding, including unfixed vulnerabilities. No CVE is suppressed and no gate is made optional. A new hosted scan must verify this remediation before publication/deployment can proceed.
