#!/usr/bin/env python
# encoding: utf-8
import sys,os

start = 2
num = 30
for n in xrange(num):
  n += start
  sys.stdout.write('#define STR_EQUALS_%d(x,y) ( ' % n)
  v = []
  for i in xrange(n):
    v.append('((x)[%d]==(y)[%d])' % (i,i))
  print '&&'.join(v), ')'
