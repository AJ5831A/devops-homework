# Git / GitHub

## Task 1: `git commit -a -m` vs `git commit -m`

- `git commit -m "msg"` only commits what's already staged (`git add`ed).
- `git commit -a -m "msg"` automatically stages every **tracked, modified**
  file before committing — but it does **not** pick up brand-new (untracked)
  files, so a fresh file still needs `git add` first.

**Real run:**

```
$ echo "line1" > file1.txt
$ git add file1.txt
$ git commit -m "Initial commit: add file1.txt"
$ git log --oneline
f280e2a Initial commit: add file1.txt

$ echo "line2 - modified" >> file1.txt
$ git status --short
 M file1.txt

$ git commit -m "Try commit without staging"
On branch master
Changes not staged for commit:
	modified:   file1.txt
no changes added to commit (use "git add" and/or "git commit -a")
# fails: file1.txt was modified but never re-staged

$ git commit -a -m "Modify file1.txt using commit -a -m"
$ git log --oneline
a4e2602 Modify file1.txt using commit -a -m
f280e2a Initial commit: add file1.txt
# succeeds: -a auto-staged the tracked, modified file1.txt
```

## Task 2: Git Cherry-Pick

**Step 1 — commits on `main`:**

```
$ git branch -m master main
$ echo "feature stub"  > file2.txt && git add file2.txt && git commit -m "Add file2.txt"
$ echo "more content"  > file3.txt && git add file3.txt && git commit -m "Add file3.txt"

$ git log --oneline
583294e Add file3.txt
4fbb05f Add file2.txt
a4e2602 Modify file1.txt using commit -a -m
f280e2a Initial commit: add file1.txt
```

**Step 2 — new branch with its own commits:**

```
$ git checkout -b feature/extra-work
$ echo "extra feature work" > feature.txt && git add feature.txt && git commit -m "Add feature.txt with extra work"
$ echo "another change" >> feature.txt && git add feature.txt && git commit -m "Update feature.txt with more changes"

$ git log --oneline
940df4e Update feature.txt with more changes
bcd95b0 Add feature.txt with extra work
583294e Add file3.txt
...
```

**Step 3 — identify a commit hash and cherry-pick it into `main`:**

```
$ git checkout main
$ git cherry-pick bcd95b0
[main bd86271] Add feature.txt with extra work
 1 file changed, 1 insertion(+)
 create mode 100644 feature.txt
```

**Step 4 — verify the change landed on `main`:**

```
$ git log --oneline
bd86271 Add feature.txt with extra work      <- cherry-picked commit, new hash on main
583294e Add file3.txt
4fbb05f Add file2.txt
a4e2602 Modify file1.txt using commit -a -m
f280e2a Initial commit: add file1.txt

$ cat feature.txt
extra feature work
```

`feature.txt` and its content are now present on `main`, with a **new** commit
hash (`bd86271`) — cherry-pick copies the *change*, not the original commit.

### A note on the other feature commit

Cherry-picking the *second* feature-branch commit (`940df4e`, which edits an
existing `feature.txt`) directly onto `main` — without first picking the
commit that created the file — produces a real conflict, since `main` never
had `feature.txt` to begin with:

```
$ git cherry-pick 940df4e
CONFLICT (modify/delete): feature.txt deleted in HEAD and modified in 940df4e
error: could not apply 940df4e...
```

This is resolved by either cherry-picking the commits in order (as done
above) or resolving the conflict manually with `git add`/`git rm` +
`git cherry-pick --continue`. Aborted here with `git cherry-pick --abort` to
keep `main` clean before picking the correct commit.
