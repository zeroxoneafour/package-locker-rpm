# package-locker-rpm
My old package locker was nice and all, but it was Arch-exclusive. I switched to Fedora, so I have to write a new script.

## how it locks things
1. Uninstalls the original RPM, if it's installed
2. Creates an RPM with a large amount of empty files. 10 empty files (\<package-name\>0-9) will be put in the RPM in the locker directories (see below)
3. Installs this RPM with the same name as the main package (creating a conflict)
4. Changes the files installed to be immutable, thus making the package impossible to uninstall/upgrade without deleting all of the files using sudo/root
5. Adds the package to the ignore list in `/etc/dnf/dnf.conf` so you can update your system as normal

### locker directories
```
/etc/package-locker/
/usr/share/package-locker/
/usr/local/etc/package-locker/
/usr/local/share/package-locker/
/var/package-locker
```
We try to avoid putting the files in places where they would interfere with the rest of the system. For example, we don't put it in `/bin/` or `/lib/`
