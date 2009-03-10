#!/usr/bin/env python
# encoding: utf-8
import sys, os, re

TEST_PACKET = '1221930210.403207 IP '\
  '(tos 0x0, ttl 64, id 36057, offset 0, flags [DF], proto TCP (6), length 67) '\
  '192.168.1.9.50159 > 192.168.1.1.80: P, cksum 0xed80 (correct), 530:545(15) '\
  'ack 1 win 65535 <nop,nop,timestamp 301940015 10089640>\n'\
  'E..C..@.@.*....	.......P.F..4:!............\n'\
  '..=/....refresh=Refresh'

TEST_PACKET1 = '1221933871.483630 IP '\
  '(tos 0x0, ttl 64, id 22678, offset 0, flags [none], proto TCP (6), length 1500) '\
  '192.168.1.1.80 > 192.168.1.9.50219: ., cksum 0x4a93 (correct), 67:1515(1448) '\
  'ack 545 win 8192 <nop,nop,timestamp 10096962 301976583>\n'

TEST_PACKET2 = '1222278824.781637 IP '\
  '(tos 0x0, ttl 64, id 24500, offset 0, flags [DF], proto TCP (6), length 167, bad cksum 0 (->37ef)!) '\
  '217.213.5.62.53343 > 89.145.106.9.80: P, cksum 0xa347 (incorrect (-> 0x212b), 1019276909:1019277024(115) '\
  'ack 1798479153 win 33304 <nop,nop,timestamp 63146508 1391054982>\n'

TEST_PACKET3 = '1222279203.970041 IP '\
  '(tos 0x0, ttl 64, id 40690, offset 0, flags [DF], proto TCP (6), length 167, bad cksum 0 (->f8b0)!) '\
  '217.213.5.62.53516 > 89.145.106.9.80: P, cksum 0xa347 (incorrect (-> 0x9e1c), 2233392456:2233392571(115) '\
  'ack 2202750765 win 33304 <nop,nop,timestamp 63150297 1391149771>\n'

class Packet(object):
  def __init__(self):
    self.header = None
    self.body = ''
  
  def __repr__(self):
    return 'Packet(%s)' % ', '.join(['%s=%s' % (k, repr(v)) for k,v in self.__dict__.items()])
  

class PacketParseError(Exception):
  pass  

class HTTPSniffer(object):
  TCP_HEADER_LEN = 40
  HEADER_RE = re.compile(r'^(?P<timestamp>[0-9\.]+) (?P<netproto>\w+) '\
    r'\(tos 0x(?P<tos>[^,]+), ttl (?P<ttl>[^,]+), id (?P<id>[^,]+), offset (?P<offset>[^,]+), '\
    r'flags \[(?P<flags>[^\]]+)\], proto (?P<proto>\w+) \((?P<unknown1>\d+)\), length (?P<length>\d+)'\
    r'.*'\
    r'\) '\
    r'(?P<sender_addr>[0-9\.]+)\.(?P<sender_port>[0-9]+) > (?P<receiver_addr>[0-9\.]+)\.(?P<receiver_port>[0-9]+): '\
    r'(?P<unknown2>[^,]+), '\
    r'cksum 0x(?P<checksum>[0-9a-f]+) \((?P<checksum_status>[^\)]+)\), '\
    r'(?P<unknown3>[\d:\(\)]+) ack (?P<ack>\d+) win (?P<win>\d+)', re.I)
  
  NUMERIC_10 = 'ack tos win length id ttl offset'.split(' ')
  NUMERIC_16 = 'checksum'.split(' ')
  NUMERIC_F = 'timestamp'.split(' ')
  
  tcpdump_rules = ['']
  
  def __init__(self, packet_handler, interface='en1', ports=[80], tcpdump_rules=[]):
    self.packet_handler = packet_handler
    self.ports = ports
    self.interface = interface
    self.tcpdump_rules = tcpdump_rules
    self.ps = None
  
  def start(self, from_file=None):
    if from_file is None:
      cmd = "tcpdump -nvlAi %s -s 0 -tt "\
        "'(%s) and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)%s'" %\
        (self.interface,
         ' or '.join(['tcp port %d' % port for port in self.ports]),
         ' '.join(self.tcpdump_rules))
      print '$ %s' % cmd
      self.ps = os.popen(cmd)
    else:
      self.ps = from_file
  
  def stop(self):
    self.ps.close()
  
  def run(self, dump_to_file=None):
    if self.ps is None:
      self.start()
    try:
      if dump_to_file is not None:
        print >> sys.stderr, 'Dumping to %s...' % dump_to_file
        for line in self.ps:
          dump_to_file.write(line)
      else:
        while self.ps:
          m = self.HEADER_RE.match(self.ps.readline())
          if m is not None:
            packet = self.parse_packet(m)
          if packet is None:
            break
          self.packet_handler(packet)
    except:
      try:
        self.stop()
        raise
      except KeyboardInterrupt:
        pass
      except:
        raise
  
  def parse_packet(self, m, debug=False):
    #print 'parsing', repr(packet_desc)
    pa = Packet()
    for k,v in m.groupdict().items():
      if k in self.NUMERIC_10:
        v = int(v, 10)
      elif k in self.NUMERIC_16:
        v = int(v, 16)
      elif k in self.NUMERIC_F:
        v = float(v)
      elif k == 'checksum_status':
        if v == 'correct':
          v = True
        else:
          v = False
      elif k == 'flags' and v == 'none':
        v = None
      pa.__dict__[k] = v
    if debug:
      print 'parsed params', pa
    # Discard ascii-mangled tcp package header
    self.ps.read(self.TCP_HEADER_LEN)
    pa.length -= self.TCP_HEADER_LEN
    if pa.length > 0:
      pa.body = ''
      while len(pa.body) < pa.length:
        #print '>> readline %r < %r' % (len(pa.body), pa.length)
        pa.body += self.ps.readline()
      if len(pa.body) > pa.length:
        pa.body = pa.body[:pa.length]
    # Discard NL added by dcpdump
    self.ps.read(1)
    return pa
  
  def packet_handler(self, packet):
    raise NotImplementedError()
  

if __name__ == '__main__':
  from optparse import OptionParser
  op = OptionParser()
  op.add_option("-i", "--interface",
                dest="interface",
                help="Network interface to attach to.",
                default='en1',
                metavar="INTERFACE")
  op.add_option("-p", "--port",
                dest="ports",
                action="append",
                default=[],
                help="TCP port to survey. This option can be repeated several times.",
                metavar="PORT")
  (opts, args) = op.parse_args()
  
  if len(opts.ports) == 0:
    opts.ports = [80]
  
  import socket
  def hostname(addr):
    try:
      name, aliaslist, addresslist = socket.gethostbyaddr(addr)
      names = [name]
      names.extend(aliaslist)
      return ', '.join(names)
    except socket.herror:
      return addr
  
  def packet_handler(packet):
    #dt = datetime()
    
    print '\n[0x%x @ %s]: %s:%s --> %s:%s' % \
      (packet.id, packet.timestamp,
       hostname(packet.sender_addr), packet.sender_port,
       hostname(packet.receiver_addr), packet.receiver_port)
    print repr(packet.body)

  s = HTTPSniffer(packet_handler,
    interface=opts.interface,
    ports=[int(p) for p in opts.ports],
    tcpdump_rules=args)
  if 0: # test parse
    try:
      s.parse_packet(TEST_PACKET2, debug=True)
    except AttributeError:
      pass
    print 'success'
    sys.exit(0)
  s.run()
