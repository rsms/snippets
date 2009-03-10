DIGIT_CHARS = ["0".."9", "a".."z", "A".."Z"].map { |r| r.to_a }.flatten
#DIGIT_CHARS = ["0".."9", "A".."Z", "a".."z"].map { |r| r.to_a }.flatten
BASE = DIGIT_CHARS.size
DIGIT_VALUES = Hash[*(0...BASE).map { |i| [ DIGIT_CHARS[i], i ] }.flatten]

def convert_base(digits, from_base, to_base)
  bignum = 0
  digits.each { |digit| bignum = bignum * from_base + digit }
  converted = []
  until bignum.zero?
    bignum, digit = bignum.divmod to_base
    converted.push digit
  end
  converted.reverse
end

class String
  def to_base62()
    convert_base(self.unpack("C*"), 256, BASE).map { |d|
      DIGIT_CHARS[d]
    }.join('')
  end

  def from_base62()
    convert_base(self.split('').map { |c|
      DIGIT_VALUES[c]
    }, BASE, 256).pack("C*")
  end
end

hex_id = "bfe8cf67df8f46ae999a341add9f100b"
puts [hex_id].pack('H*').to_base62

raw_id = [hex_id].pack('H*')
b62_id = encode(raw_id)
puts b62_id
b62_id = convert_base([hex_id].pack('H*').unpack("C*"), 256, BASE).map { |d| DIGIT_CHARS[d] }.join('')
puts b62_id
