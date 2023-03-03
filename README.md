# direnv-projectenv

helper script for [direnv](https://direnv.net) to manage
consistent environments for software development repositories.

inspired by [direnv-helpers](https://github.com/steve-ross/direnv-helpers/), but more opinionated.

principles:

* support node.js and Java in a simple, opinionated way
* set all tool versions from ".env" files (aka dotenv)
* fail and warn if something goes wrong and dont block the shell prompt
* do not manage or install versions
* detect version manager installations (`nvm`, `sdk`) but do not call them (just use their env var/and or default installation directories)
* allow custom configuration per system via env vars (e.g. if `nvm` is not used a `$NODE_VERSIONS` var can be used to configre the directory where node.js versions are searched)

# development

## linting

<shellcheck.net> is used to lint the shell script.

```sh
npm i # currently calls your local package manager to install
npm run lint
```

## work in progress

tested/supported envs:

* [x] macOS, bash, nvm installed
* [ ] macOS, oh-my-zsh, nvm auto-hook
* [ ] Windows…
* [ ] Ubuntu…

## (draft) how to use

* install direnv, nvm
* open project, and allow the direnv file (needs only to be done once).

    direnv allow .

* if something went wrong, run

    direnv reload

* if that did not fix it, see debug info to see whats up
    direnv direnv status

* how to update the helper scripts for your project

* clone the script repo, e.g. git clone …
* replace the "fetch srcipt" line with `. ~/path/to/your/sripts/repo`
* ensure that everything is working

    direnv allow # allow your changes, and reload the env
