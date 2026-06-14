# Awesome Vagrant Directory

## Dependencies

In your Linux Host OS, make sure you have installed:

- vagrant
- virtualbox (and properly loaded)

> unload kvm (and kvm\_intel or kvm\_amd) modules first.
> load vboxnetflt, vboxnetadp and vboxdrv modules.

## Shared Folders

- Common home files (`bashrc`, `vimrc`, `id_rsa.*`) are synced automatically.
- A default `$HOME/work` folder is automatically shared if it exists.

## Use it

Simply go to directory you want and provision it:

```console
cd ./vms/jammy
vagrant up
vagrant ssh
vagrant halt
vagrant destroy
```

And have fun.

## Customize It

1. First case: Edit files inside `./vagrant` directory (specially `distro.rb` files).
2. Or create new files with your needs and link them to new `vms/` sub-directories.

## Contributing

Feel free to open PRs submitting new generic usage files or functions.
