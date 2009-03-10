#!/bin/sh
if [ $# -lt 2 ]; then
  echo "usage: $0 <repository url> <checkout path>" >&2
  echo
  echo "Important:" >&2
  echo "  This script expects the Subversion repository to have at least two" >&2
  echo "  distinctive directories:" >&2
  echo "    trunk/" >&2
  echo "    tags/" >&2
  echo "  The trunk/ will be checked out to ./\$(basename <repository url>)" >&2
  echo "  and tags/ will be svn info:ed in order to hg tag revisions in trunk/." >&2
  echo
  echo "Example:" >&2
  echo "  $0 http://svn.hunch.se/smisk smisk" >&2
  exit 1
fi

SVN_REPO="$1"
CHECKOUT_PATH="$2"

hgimportsvn $SVN_REPO/trunk "$CHECKOUT_PATH" || exit 1
cd "$CHECKOUT_PATH"
hgpullsvn || exit 1

echo 'Creating public tags...'
SVN_TAGS=$(svn ls $SVN_REPO/tags)
HG_TAGS=$(hg tags)
for tag_name in $SVN_TAGS; do
  tag_name=$(echo $tag_name | sed -E 's/\/$//g')
  NFO=$(svn info "$SVN_REPO/tags/$tag_name")
  TAG_REV=$(echo "$NFO" | grep 'Last Changed Rev' | sed -E 's/[^0-9]+//g')
  TAG_DATE=$(echo "$NFO" | grep 'Last Changed Date' | sed -E 's/(Last Changed Date: |\(.+\)|\+[0-9]{4}$)//g' | awk '{printf("%s %s", $1, $2)}')
  TAG_USER=$(echo "$NFO" | grep 'Last Changed Author' | sed 's/Last Changed Author: //g')
  HG_REV=$(echo "$HG_TAGS" | grep -E "svn.$TAG_REV[ \t]+" | sed -E 's/^.+ +([0-9]+):.+$/\1/g')
  if [ "$HG_REV" == "" ]; then
    TAG_REV_LOWER=$(expr $TAG_REV - 1)
    echo "No svn revision $TAG_REV for tag $tag_name in trunk." >&2
    echo "  You might want to make a manual tag with a close-by revision, for example with svn r $TAG_REV_LOWER:" >&2
    HG_REV=$(echo "$HG_TAGS" | grep -E "svn.$TAG_REV_LOWER[ \t]+" | sed -E 's/^.+ +([0-9]+):.+$/\1/g')
    echo "  hg tag -r $HG_REV -d '$TAG_DATE' -u '$TAG_USER' '$tag_name'"
  else
    hg tag -r $HG_REV -d "$TAG_DATE" -u "$TAG_USER" "$tag_name"
  fi
done

echo 'Removing .svn meta directories...'
find . -regex '.*/.svn' | xargs rm -fr

echo 'Done!'
