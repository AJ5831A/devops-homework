# Linux Fundamentals

## Task 1: Soft Link vs Hard Link

**Difference**

| | Hard Link | Soft (Symbolic) Link |
|---|---|---|
| What it is | Another directory entry pointing to the *same inode* | A separate file that stores a *path* to the target |
| Across filesystems | No | Yes |
| Can link a directory | No | Yes |
| If the original is deleted | Still works — data isn't freed until all hard links are removed | Breaks ("dangling" link) |
| Inode number | Same as original | Different from original |

**Commands**

```bash
ln  original.txt hardlink.txt     # create a hard link
ln -s original.txt softlink.txt   # create a soft/symbolic link
```

**Practice — real run**

```
$ echo "original file content" > original.txt
$ ln original.txt hardlink.txt
$ ln -s original.txt softlink.txt

$ ls -li
1392602 -rw-r--r--  2 aryanjakhar  staff  22 hardlink.txt
1392602 -rw-r--r--  2 aryanjakhar  staff  22 original.txt
1392605 lrwxr-xr-x   1 aryanjakhar  staff  12 softlink.txt -> original.txt

$ stat -f "Links: %l" original.txt
Links: 2

$ rm original.txt

$ cat hardlink.txt        # still works — inode data is still there
original file content

$ cat softlink.txt        # broken — the path it pointed to is gone
cat: softlink.txt: No such file or directory

$ ls -li
1392602 -rw-r--r--  1 aryanjakhar  staff  22 hardlink.txt
1392605 lrwxr-xr-x   1 aryanjakhar  staff  12 softlink.txt -> original.txt
```

Note `hardlink.txt` shares inode `1392602` with the original (same file, two
names — deleting one name just decrements the link count), while
`softlink.txt` has its own inode (`1392605`) and only stores a path, so it
breaks once that path stops resolving.

**Interview note:** hard links can't span filesystems/partitions and can't
point to directories, because they rely on a shared inode; symlinks can do
both because they're just a stored path.

## Task 2: `adduser` vs `useradd`

| | `useradd` | `adduser` |
|---|---|---|
| Type | Low-level binary | Higher-level, interactive Perl/shell script wrapping `useradd` |
| Home directory | Not created by default (needs `-m`) | Created automatically |
| Password | Not set (needs a separate `passwd` step) | Prompts for one interactively |
| Availability | All Linux distros | Debian/Ubuntu (and derivatives) |

**Preferred on Ubuntu/Debian:** `adduser` — it's the friendlier, interactive
wrapper that sets sensible defaults (home dir, shell, prompts for a password)
in one step, whereas `useradd` requires several follow-up commands to reach
the same state and is easy to misconfigure.

```bash
sudo adduser testuser        # recommended on Ubuntu/Debian
```

**Executed on 2026-10-07 in the disposable Ubuntu 24.04 Colima VM.**
`sudo adduser --disabled-password --gecos "Homework test user" hwtestuser`
created the home directory and Bash account; `id` and `getent passwd` verified
it, then `deluser --remove-home` cleaned up the lab account. See the
[actual transcript](../evidence/linux/ubuntu-users-journal.log).

## Task 3: `journalctl`

`journalctl` reads and displays logs collected by `systemd-journald`
(the systemd logging service) — kernel messages, service stdout/stderr, and
boot logs, all in one place.

```bash
journalctl                       # view the full system log
journalctl -u nginx.service      # view logs for a specific service
journalctl -f                    # follow logs live, like tail -f
journalctl --since "1 hour ago"  # filter by time
journalctl -p err                # filter by priority (errors only)
```

**Executed:** `sudo journalctl -u docker.service --since "10 minutes ago" --no-pager -n 20`
returned the Docker daemon startup and service logs from systemd. The same
[Ubuntu transcript](../evidence/linux/ubuntu-users-journal.log) includes the command/output.

## Task 4: Linux Command Cheat Sheet

Commands reviewed and practiced (standard file/process/permission ops):

| Command | Purpose |
|---|---|
| `ls -la` | List all files, including hidden, with details |
| `cd` / `pwd` | Change / print working directory |
| `cp` / `mv` / `rm` | Copy / move-rename / remove files |
| `mkdir -p` | Create a directory (and parents) |
| `chmod` / `chown` | Change permissions / ownership |
| `grep` | Search text by pattern |
| `find` | Search for files by name/type/time |
| `ps aux` / `top` | List / monitor running processes |
| `df -h` / `du -sh` | Disk free space / directory size |
| `tar -czvf` | Archive and compress files |
| `chmod +x` | Make a file executable |
| `sudo` | Run a command with elevated privileges |
