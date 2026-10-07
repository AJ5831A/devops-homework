# Executed Docker labs — 2026-10-07

Student: Aryan Jakhar, 24BCS10305. Runtime: Docker Engine29.5.2 inside the
disposable Ubuntu24.04 Colima VM on this Mac. `runtime.log` is the complete
observed build/run transcript; it contains transient curl retries while new
containers started, followed by successful responses. The script exited0.

- All six Hello World applications built and ran concurrently. The six PNGs are direct browser captures of their pages.
- Multi-stage Go app built successfully and answered on host port8080. See `multistage-response.txt`, `multistage-app.png` and `docker-ps.txt`.
- Three networks were created. Backend joined two networks; frontend reached backend, failed DNS resolution for isolated database, then reached database after joining its network.
- Apache using host networking answered on the Ubuntu VM's port80. This is the Linux Docker host, not macOS's network namespace.
- Bind-mount content changed from Hello students to the updated message without a container restart. `bindmount.log` records identical StartedAt timestamps before/after; browser screenshots show both pages.

The networking/Apache/ps PNGs are labeled renderings of actual transcript
excerpts. Original text files retain complete output. The initial bind-mount
run used a temporary path linked into Colima's shared home directory; the
separate bindmount.log directly mounts the repository's ignored
`.runtime-bindmount` folder. The replay script now uses that portable shared path.

Run `bash scripts/run-docker-evidence.sh` from the repository to reproduce.
The containers/networks use `hw-` prefixes; the script does not touch unrelated
containers. MySQL has no published port and uses a disposable empty-password
lab database solely for network reachability checks.
