#!/usr/bin/ruby

#require 'rmagick'
require 'mini_magick'
require 'mini_exiftool'

sizes = {
  album1:  [ 240,  160],
  album2:  [ 380,  253],
  macbook: [1280,  800],
  samsung: [1920, 1200]
}

exit unless ARGV[0]

# TODO: check if ARGV[0] is directory, and strip last /

Dir.mkdir "#{ARGV[0]}/sizes" rescue nil

skip_sizes = []
sizes.values.each do |width, height|
  directory = "#{ARGV[0]}/sizes/#{width}x#{height}"
  if not File.directory? directory
    Dir.mkdir "#{ARGV[0]}/sizes/#{width}x#{height}" rescue nil
  else
    skip_sizes << "#{width}x#{height}"
  end
end

first = true
photos = []
date = nil
Dir["#{ARGV[0]}/*.jpg"].each do |filename|

  # TODO: use ruby lib to determine file basename
  basename = filename.split('/').last
  photos << basename

  if first
    exif = MiniExiftool.new filename
    date = exif['datetimeoriginal'].to_s.split(' ').first
    first = false
  end

  sizes.values.each do |width, height|
    if not skip_sizes.include? "#{width}x#{height}"
      directory = "#{ARGV[0]}/sizes/#{width}x#{height}"
      puts "Resizing #{basename} > #{width}x#{height}"

      image = MiniMagick::Image.open(filename)

      # image[:width], image[:height]
      image.combine_options do |c|
        c.resize "#{width}x#{height}>"
        c.quality 85
      end
      image.write "#{directory}/#{basename}"
    end
  end
end

name = ARGV[0].split('/').last
title = name
index = photos[0]
content = name

album = <<ALBUM
---
title: %s
date: %s
baseurl: https://s3-eu-west-1.amazonaws.com/bertspaan.nl/albums
index: %s
secret: true
photos:
%s
---

%s
ALBUM

File.write("#{ARGV[0]}/../#{name}.json", album % [title, date, index, photos.map {|p| "  - #{p}" }.join("\n"), content])
