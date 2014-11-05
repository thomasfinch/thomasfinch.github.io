#Generate the Packages and Packages.bz2 files
dpkg-scanpackages -m . /dev/null > Packages
bzip2 -f -k Packages

#Get MD5 hashes of Packages and Packages.bz2, and put that info at the end of the release file
# PACKAGES_SIZE=$(stat -f%z Packages)
# PACKAGES_BZ2_SIZE=$(stat -f%z Packages.bz2)
# PACKAGES_MD5=$(md5 -q Packages)
# PACKAGES_BZ2_MD5=$(md5 -q Packages.bz2)
# cat Release-orig > Release
# echo -e "MD5Sum:\n" $PACKAGES_MD5 $PACKAGES_SIZE "Packages " >> Release
# echo "" $PACKAGES_BZ2_MD5 $PACKAGES_SIZE "Packages.bz2 " >> Release

#Sign the release file
# rm -f Release.gpg
# gpg -abs -o Release.gpg Release