def c(bg, fg):
  bg = float(bg)
  fg = float(fg)
  return (max(bg, fg) - min(bg, fg)) / float(0xffffff)

def cf(bg, fg):
  return '#%x <> #%x = %.0f%%' % (int(bg), int(fg), c(bg, fg) * 100.0)

print cf(bg=0xffffff, fg=0x555555) 
print cf(bg=0xf8f8f8, fg=0x818181)
print cf(bg=0xe9f5fe, fg=0x555555)
print cf(bg=0xffffff, fg=0x555555)