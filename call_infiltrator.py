# encoding: utf-8
'''Infiltrates and logs calls to functions.
'''
import sys, inspect, time, functools

FTYPE_FUNCTION = 'function'
FTYPE_INSTANCE_METH = 'instance method'
FTYPE_CLASS_METH = 'class method'
FTYPE_STATIC_METH = 'static method'

def __ts():
  t = time.time()
  us = (t - float(int(t))) * 1000000.0
  return time.strftime('%H:%M:%S.%%6.0f') % us

def mk_stream_handler(stream):
  def handler(ftype, func, *va, **kw):
    args = parse_args(func, *va, **kw)
    print >> stream, 'TRACE %s ENTER %15s %s(%s)' % (__ts(), ftype, func.__name__, ', '.join(args))
    def exit_handler(rv, etyp, exc, etb):
      msg = 'TRACE %s EXIT  %15s %s(%s)' % (__ts(), ftype, func.__name__, ', '.join(args))
      if etyp:
        msg += ' --! ' + repr(exc)
      else:
        msg += ' --> ' + repr(rv)
      print >> stream, msg
    return exit_handler
  return handler

def mk_file_handler(filename):
  return mk_stream_handler(fopen(filename, 'w'))

stderr_handler = mk_stream_handler(sys.stderr)
stdout_handler = mk_stream_handler(sys.stdout)

def __format_arg_value(kv):
  return '%s=%r' % kv

def parse_args(fn, *va, **kw):
  '''Parse argument into a pretty ordered list.
  '''
  code = fn.func_code
  argcount = code.co_argcount
  argnames = code.co_varnames[:argcount]
  fn_defaults = fn.func_defaults or list()
  argdefs = dict(zip(argnames[-len(fn_defaults):], fn_defaults))
  positional = map(__format_arg_value, zip(argnames, va))
  defaulted = [__format_arg_value((a, argdefs[a])) for a in argnames[len(va):] if a not in kw]
  nameless = map(repr, va[argcount:])
  keyword = map(__format_arg_value, kw.items())
  return positional + defaulted + nameless + keyword

def infiltrator(fn, handler=stderr_handler, ftype=None):
  if ftype is None:
    ftype = FTYPE_FUNCTION
    try:
      if fn.im_self == None:
        ftype = FTYPE_CLASS_METH
      else:
        ftype = FTYPE_INSTANCE_METH
    except AttributeError:
      if '@staticmethod' in inspect.getsource(fn):
        # This is a guess
        ftype = FTYPE_STATIC_METH
  
  @functools.wraps(fn)
  def wrapped(*v, **k):
    exit_handler = handler(ftype, fn, *v, **k)
    if exit_handler:
      rv = None
      try:
        rv = fn(*v, **k)
        exit_handler(rv, None, None, None)
        return rv
      except:
        exit_handler(None, *sys.exc_info())
        raise
    else:
      return fn(*v, **k)
  return wrapped

def infiltrate_instancemethod(klass, method, handler=stderr_handler):
  mname = method.__name__
  if mname.startswith("__") and not mname.endswith("__"):
    mname = "_%s%s" % (method.im_class.__name__, mname)
  never_infiltrate = "__str__", "__repr__", # Avoid recursion printing method calls
  if mname in never_infiltrate:
    pass
  elif method.im_self is not None:
    setattr(klass, mname, classmethod(infiltrator(method.im_func, handler, ftype=FTYPE_CLASS_METH)))
  else:
    setattr(klass, mname, infiltrator(method, handler, ftype=FTYPE_INSTANCE_METH))

def infiltrate_class(klass, handler=stderr_handler):
  for _, method in inspect.getmembers(klass, inspect.ismethod):
    infiltrate_instancemethod(klass, method, handler)
  for _, fn in inspect.getmembers(klass, inspect.isfunction):
    setattr(klass, fn.__name__, staticmethod(infiltrator(fn, handler, ftype=FTYPE_STATIC_METH)))

def infiltrate_module(mod, handler=stderr_handler):
  for fname, fn in inspect.getmembers(mod, inspect.isfunction):
    setattr(mod, fname, infiltrator(fn, handler))
  for _, klass in inspect.getmembers(mod, inspect.isclass):
    infiltrate_class(klass, handler)

infiltrate_function = infiltrator
infiltrate_staticmethof = infiltrator

def infiltrate(something, handler=stderr_handler):
  '''Infiltrate an entire module, a whole class, a method or a function.
  '''
  if inspect.ismodule(something):
    infiltrate_module(something, handler)
  elif inspect.isclass(something):
    infiltrate_class(something)
  elif inspect.ismethod(something):
    infiltrate_instancemethod(something)
  elif inspect.isfunction(something):
    infiltrate_function(something)
  else:
    raise TypeError('unable to infiltrate objects of type %s' % type(something).__name__)


if __name__ == '__main__':
  class Mos(object):
    def __init__(self, arg=123):
      super(Mos, self).__init__()
      print 'Mos.__init__ called OK'
    
    def fname(self, name):
      print 'Mos.fname called OK'
    
    def close(self, a='A', bcd=123):
      print 'Mos.close called OK'
      raise TypeError('me no like ice cream. grrr')
    
    def hej(self, fisk='fishy', *va, **kw):
      print 'Mos.hej called OK with %r, %r' % (va, kw)
    
    @classmethod
    def clsmeth(cls):
      print 'Mos.clsmeth called OK'
    
    @staticmethod
    def staticmeth():
      print 'Mos.staticmeth called OK'
    
    def staticmeth2():
      msg = 'Mos.staticmeth2 called OK'
      print msg
    staticmeth2 = staticmethod(staticmeth2)
  
  infiltrate(Mos)
  
  mos = Mos()
  mos.fname('moset')
  try:
    mos.close()
  except:
    pass
  mos.hej('mos')
  mos.hej('boll', 'kista')
  mos.hej('boll', 'kista', fysik=1234)
  Mos.clsmeth()
  Mos.staticmeth()
