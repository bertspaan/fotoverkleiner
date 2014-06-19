require 'rmagick'
require 'aws-sdk'


puts ARGV[0]

# TODO: check if file exists,
# check if file or directory

img = Magick::Image::read(ARGV[0]).first
thumb = img.scale(125, 125)
thumb.write "/Users/bert/Downloads/honden.jpg"

#img = Image.new
# thumb = img.scale(125, 125)
# thumb.write "thumb.gif"

# AWS.config(access_key_id: 'AKIAJ5ID7YST55JEDERA', secret_access_key: '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', region: 'eu-west-1')


s3 = AWS::S3.new(
  access_key_id: 'AKIAJB2S52DMLDNL5TGQ',
  secret_access_key: '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',
  region: 'eu-west-1')

bucket = s3.buckets['bertspaan.nl']

obj = bucket.objects['blog/honden.jpg']

obj.write(Pathname.new("/Users/bert/Downloads/honden.jpg"))
