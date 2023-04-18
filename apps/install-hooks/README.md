# Install hooks

Installs git hooks, configs, and other such files to the (probably) freshly
cloned repo's .git folder. Will override any existing hooks. It's idempotent, so
running multiple times is harmless.

This includes a self-updating hook, so that when there's a change to the repo,
it will re-run this script.
