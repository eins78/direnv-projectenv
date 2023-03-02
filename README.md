# direnv-projectenv

helper script for [direnv](https://direnv.net).

inspired by [direnv-helpers](https://github.com/steve-ross/direnv-helpers/), but more opinionated.

principles:

* set all tool version from ".env" files (aka dotenv)
* fail and warn if something goes wrong and dont block the shell prompt
* do not manage or install versions
* detect version manager installations (`nvm`, `sdk`) but do not call them (just use their env var/and or default installation directories)

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

* if something **went wrong**, run

    direnv reload

* if that did not fix it, see **debug info** to see whats up

    direnv status

* if that did not fix it, see **debug info** to see whats up

    direnv block

* how to update the helper scripts for your project

  * clone the script repo, e.g. git clone …
  * replace the "fetch srcipt" line with `. ~/path/to/your/sripts/repo`
  * ensure that everything is working

        direnv allow # allow your changes, and reload the env
