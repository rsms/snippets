#!/usr/bin/env ruby
# Exports FontExplorer font library as one zip-file per font family.

FONT_LIBRARY = '/Users/rasmus/Font Library'
EXPORT_DIR = '/Volumes/hal.spotify.net/var/filerepo/fonts/MAC/rasmus'

def families()
  v = []
  Dir.foreach(FONT_LIBRARY) {|letter|
    if letter != '.' and letter != '..' and File.directory?("#{FONT_LIBRARY}/#{letter}") then
      #puts "Exporting families #{letter}..."
      Dir.foreach("#{FONT_LIBRARY}/#{letter}") {|family|
        family_path = "#{FONT_LIBRARY}/#{letter}/#{family}"
        if family != '.' and family != '..' and File.directory?(family_path) then
          v.push(family_path)
        end
      }
    end
  }
  v
end

# Export to zip files
for path in families do
  letter_path = File.dirname(path)
  letter = File.basename(letter_path)
  family_name = File.basename(path)
  puts "Exporting #{family_name}"
  `cd '#{letter_path}' && mkdir -p '#{EXPORT_DIR}/#{letter}' && /usr/bin/ditto -c -k -X --rsrc '#{family_name}' '#{EXPORT_DIR}/#{letter}/#{family_name}.zip'`
end
