# encoding: utf-8
'''untitled
'''
import sys, os, random as _random
try:
  rnd = _random.SystemRandom().random
except:
  rnd = _random.random

# emulate C stdlib random()
def random():
  return int(rnd() * RAND_MAX)

RAND_MAX = (2**31)-1
probability = 0.2

if 1:
  trues = 0.0
  falses = 0.0
  for i in xrange(10000):
    if float(random()) / float(RAND_MAX) < probability:
      trues += 1.0
    else:
      falses += 1.0
  total = trues+falses
  print 'distribution: true %.0f%%, false %.0f%%' %\
    ((trues/total)*100.0, (falses/total)*100.0)
