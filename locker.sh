#!/bin/bash

# locker.sh
# Usage - ./locker.sh <package to lock>

returndir="$(pwd)" # cd back after script is done

# install the package - required for file type checking
# assuming it's on repos
echo "Installing original package..."
sudo dnf install "$1"

# create a tmp directory for working
tmpdir=$(mktemp -d)
cd $tmpdir

# create the build files
echo "Creating files..."
files=""
dirs=""
for file in $(rpm -ql $1); do
	if [[ -d $file ]]; then
		dirs="$dirs ${file:1}"
	elif [[ -f $file ]]; then
		if ! [[ "$file" =~ "^(\/usr)?\/lib(64)?\/[^\/]*$" ]]; then # regex checking so we don't create empty files in directories where they're complained about (ex. /usr/lib)
			files="$files ${file:1}"
		fi
	fi
done

mkdir -p files/${1}-1.0.0 # create a files directory for the tar.gz
cd files/${1}-1.0.0

for dir in $dirs; do mkdir -p $dir; done # make dirs

for file in $files; do # this actually makes the files
	mkdir -p $(dirname $file)
	touch $file
done

cd ..

tar -cf "$1"-1.0.0.tar.gz "$1"-1.0.0

cd ..

# create files list for the files section of the rpm config file, just the same thing but with newlines
fileslist=""
for file in $files $dirs; do
	fileslist="${fileslist}
/${file}"
done

# setup rpm tree
echo "Setting up RPM for build..."
mkdir rpmbuild
cd rpmbuild
for dir in "BUILD BUILDROOT RPMS SOURCES SPECS SRMPS"; do mkdir $dir; done

# setup the rpm for building
mv ../files/"$1"-1.0.0.tar.gz SOURCES/

# create the rpm config file
cat << EOF >> SPECS/$1.spec
Name: $1
Version: 1.0.0
Release: 1%{?dist}
Summary: Blocking package $1
BuildArch: noarch

License: CC0
Source0: $1-1.0.0.tar.gz

%description
This package blocks the installation of package $1.

%prep
%setup -q

%install
rm -rf \$RPM_BUILD_ROOT
for dir in ${dirs}; do
	mkdir -p \$RPM_BUILD_ROOT/\$dir
done

for file in ${files}; do
	mkdir -p \$RPM_BUILD_ROOT/\$(dirname \$file)
	cp \$file \$RPM_BUILD_ROOT/\$file
done

%files
${fileslist}
EOF

# build the rpm
echo "Building RPM..."
rpmbuild -bb "$tmpdir"/rpmbuild/SPECS/"$1".spec --define '_topdir '${tmpdir}'/rpmbuild'

# warn the user
echo "Warning - From this point on, you will have to create a custom script to remove $1. Continue?"
read -n1 -r -p "[y/n] " answer
echo ""

if ! [[ $answer == [Yy]* ]]; then
	echo "Cleaning up..."
	rm -rf $tmpdir
	cd "$returndir"
	exit 0
fi

# delete original package
echo "Removing original package..."
sudo rpm -e "$1"
 
# install the rpm
echo "Installing RPM $1..."
sudo rpm -ivh "$tmpdir"/rpmbuild/RPMS/noarch/* --quiet

# make files immutable
echo "Making files immutable..."
for file in $files; do
	sudo chattr +i /$file
done

# prevent updating the package
echo "Fixing /etc/dnf/dnf.conf..."
if [[ $(grep "^exclude" /etc/dnf/dnf.conf > /dev/null; echo $?) == *1* ]]; then
	echo "excludepkgs=$1*" | sudo tee -a /etc/dnf/dnf.conf > /dev/null
else
	# check if /etc/dnf/dnf.conf was already written to
	if [[ $(grep "$1" /etc/dnf/dnf.conf > /dev/null; echo $?) == *1* ]]; then
		# idk how this sed works
		sed '/^excludepkgs/s/$/ '$1'*/' /etc/dnf/dnf.conf | sudo tee /etc/dnf/dnf.conf > /dev/null
	fi
fi

# clean up and return to starting directory
echo "Cleaning up..."
rm -rf $tmpdir
cd "$returndir"
