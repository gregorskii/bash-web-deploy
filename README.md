# Laravel Deploy Shell Script

```
TODO:

This is used in several projects, but project specfic code was removed. Code needs to be tested against a blank server with a default project.

Will do ASAP
```

Deploys a laravel site to a remote server using SSH and RSYNC.

**Features:**
* Jenkins workspace support
* Pulls from remote repo, or updates if .git folder is present
* Detects changes to package.json/composer.json/bower.json and runs respective installer/updater on git pull
* Runs gulp build, can be replaced with any task runner targets
* Creates hashed symlink folder for assets
* Argument checking and colored error logs
* Can checkout and cache locally different branches/features from a git repo
* Can destroy local cache when a full rebuild is needed via --fresh=true
* Can be sourced directly by other processes as a function, or run directly via sh
* Defines deploy SSH user, currently uses password auth, TBD update with key based auth as an argument

# Instructions

Add server IPs and server webroot names (ignoring /var/www) to hosts.txt separated by tab, multiple servers separated by newlines
Update the included files being sent to the server in deploy-includes.txt

# Running

```
sh deploy.sh --branch=develop
```

**deploy.sh:**

Purpose: Facilitates building and deploying the front end website to remote servers

| Argument | Required | Default | Example | Description |
|---|---|---|---|---|
| --branch | True | None | --branch=develop | Defines the branch to deploy |
| --fresh | False | False | --fresh=[true|false] | Defines whether the cached copy of the repo should be destroyed on run |