import sys

folk = []
for line in sys.stdin:
  folk.append(line)

folk.sort(lambda a,b: a[a.rindex(' '):] == b[b.rindex(' '):])

for line in folk:
  print line
