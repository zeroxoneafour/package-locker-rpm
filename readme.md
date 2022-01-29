# package-locker-rpm
My old package locker was nice and all, but it was Arch-exclusive. I switched to Fedora, so I have to write a new script.

## how it locks things
1. Installs the original RPM, if it's not installed. Then uninstalls it.
2. Creates an RPM containing the same files, but empty. Files in the `/usr/lib/` and `/usr/lib64/` directories will not be created. Files in `/usr/bin/` will not be executable.
3. Installs this RPM with the same name as the main package (creating a conflict)
4. Changes the files installed to be immutable, thus making the package impossible to uninstall/upgrade without deleting all of the files using sudo/root
5. Adds the package to the ignore list in `/etc/dnf/dnf.conf` so you can update your system as normal
