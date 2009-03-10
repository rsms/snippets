cat /var/log/lighttpd/access.log |\
  zcat /var/log/lighttpd/access.*.gz |\
  grep '/idol/' |\
  grep -v 'livebloggen.se/'|\
  awk -F ' ' '{ print $11 }' |\
  sort |\
  uniq -c |\
  sort -r -n > idol-referrer-toplist.txt