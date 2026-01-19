---
description: "Initialize git repository and push to GitHub. Sets up git, creates initial commit, and pushes to remote."
---

# Git Repository Initializer

Initialize a new git repository and push it to GitHub in one command.

---

## The Job

1. Gather GitHub username and repository name from user
2. Initialize git with `main` as default branch
3. Add all files and create initial commit
4. Configure remote origin
5. Push to GitHub

---

## Step 1: Gather Information

Ask the user these questions:

```
Before initializing, I need some information:

1. What is your GitHub username?
   (Type your username, e.g., "octocat")

2. What should the repository name be?
   A. Use current directory name: "[CURRENT_DIR_NAME]"
   B. Other: [please specify]
```

**Notes:**
- Replace `[CURRENT_DIR_NAME]` with the actual directory name (use `basename $(pwd)`)
- Wait for user response before proceeding

---

## Step 2: Pre-Flight Checks

Before running git commands, check for potential issues:

### Check 1: Existing .git directory

Run `ls -la` to check if `.git` exists.

**If .git exists, ask:**
```
This directory already has a git repository. What would you like to do?

A. Abort - do not modify existing repository
B. Remove existing .git and start fresh (WARNING: loses all git history)
C. Just add remote and push (keep existing history)
```

### Check 2: Existing remote

If `.git` exists, run `git remote -v` to check for existing remotes.

**If remote "origin" exists, ask:**
```
Remote 'origin' already exists pointing to: [EXISTING_URL]

What would you like to do?

A. Abort - keep existing remote
B. Replace with new remote (git@github.com:[user]/[repo].git)
```

---

## Step 3: Execute Git Commands

Run these commands in sequence. Stop immediately if any command fails.

### 3.1: Initialize Git (if needed)
```bash
git init -b main
```

### 3.2: Stage All Files
```bash
git add -A
```

### 3.3: Create Initial Commit
```bash
git commit -m "Initial commit

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

**Note:** If there are no files to commit, inform the user and ask if they want to proceed with just setting up the remote.

### 3.4: Add Remote Origin
```bash
git remote add origin git@github.com:[USERNAME]/[REPO_NAME].git
```

### 3.5: Push to Main
```bash
git push -u origin main
```

---

## Step 4: Handle Push Failure

If `git push` fails, diagnose the issue:

### SSH Key Issues
If error contains "Permission denied" or "Could not read from remote repository":
```
Push failed: SSH authentication issue.

Please verify:
- SSH key exists: ls ~/.ssh/id_*.pub
- SSH key added to GitHub: https://github.com/settings/keys
- Repository created on GitHub: https://github.com/[USERNAME]/[REPO_NAME]

To test SSH connection: ssh -T git@github.com

Would you like me to:
A. Show instructions for setting up SSH keys
B. Try using HTTPS instead (https://github.com/[USERNAME]/[REPO_NAME].git)
C. Abort and let you fix the issue manually
```

### Repository Doesn't Exist
If error contains "Repository not found":
```
The repository does not exist on GitHub.

Please create it first:
1. Go to https://github.com/new
2. Name it exactly: [REPO_NAME]
3. Do NOT initialize with README (we'll push our own)
4. Click "Create repository"

Then tell me to try pushing again.
```

### Branch Already Exists / Push Rejected
If error contains "rejected" or "non-fast-forward":
```
Push rejected: Remote already has commits.

Options:
A. Pull and merge first (recommended if repo has README/LICENSE)
B. Force push (WARNING: overwrites remote - use only for empty repos)
C. Abort
```

---

## Step 5: Success Confirmation

After successful push, display:

```
Repository initialized and pushed successfully!

Repository: https://github.com/[USERNAME]/[REPO_NAME]
Branch: main
Remote: origin -> git@github.com:[USERNAME]/[REPO_NAME].git

Next steps:
- View your repo: https://github.com/[USERNAME]/[REPO_NAME]
- Clone elsewhere: git clone git@github.com:[USERNAME]/[REPO_NAME].git
```

---

## Checklist

Before completing, verify:

- [ ] Asked for GitHub username
- [ ] Confirmed repository name (or used directory name)
- [ ] Checked for existing .git directory
- [ ] Initialized git with `main` branch (if needed)
- [ ] Added all files
- [ ] Created initial commit with Co-Authored-By
- [ ] Added remote origin
- [ ] Pushed to main
- [ ] Displayed success message with repository URL
