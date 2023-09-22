# Modules

Modules that make the set-up of my personal NixOS machines easier. E.g., by
either abstracting or simplifying existing modules and just hard coding some of
the options to sensible (and very much opinionated) defaults.

The idea here is to provide one individual simplified solution rather than
having 20 alternatives with many knobs to tweak. That's why some are just
wrappers around other services, for the most part it's all just abstraction
layers.

So if, for example, you want a backup service, you don't care how it's done as
long as it works. So you would use the “backup” module, and forget about the
implementation.

In theory this also allows for changing backends in case something gets
deprecated, or a much better alternative appears; and if done right (not saying
that I do things right here, but I do try) you won't even notice the change.
