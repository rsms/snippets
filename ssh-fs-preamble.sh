SSHFS=$(which sshfs);if [ "$SSHFS" == "" ]; then
  if [ -x /Applications/sshfs.app/Contents/Resources/sshfs-static-10.5 ]; then
    ln -s /Applications/sshfs.app/Contents/Resources/sshfs-static-10.5 /usr/bin/sshfs
    SSHFS=/usr/bin/sshfs
  else
    echo 'Unable to find sshfs. Looked in PATH and /Applications/sshfs.app/Contents/Resources/sshfs-static-10.5' >&2
    exit 1
  fi
fi
mkdir -p /Volumes/hal
sshfs hal:/ /Volumes/hal -oreconnect,volname=hal
