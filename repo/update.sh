#Generate the Packages and Packages.bz2 files
dpkg-scanpackages -m . /dev/null > Packages
bzip2 -f -k Packages

#Do all the md5 stuff here...
PACKAGES_SIZE=$(stat -f%z Packages)
PACKAGES_BZ2_SIZE=$(stat -f%z Packages.bz2)
PACKAGES_MD5=$(md5 -q Packages)
PACKAGES_BZ2_MD5=$(md5 -q Packages.bz2)
cat Release-orig > Release
echo -e "MD5Sum:\n" $PACKAGES_MD5 $PACKAGES_SIZE "Packages " >> Release
echo "" $PACKAGES_BZ2_MD5 $PACKAGES_SIZE "Packages.bz2 " >> Release

#Sign the release file
gpg -abs -o Release.gpg Release