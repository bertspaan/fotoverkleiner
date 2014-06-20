# encoding: utf-8

require 'sinatra'
require 'json'

class Fotoverkleiner < Sinatra::Base
  config = JSON.parse(File.read('./config.json'), symbolize_names: true)
  sizes = JSON.parse(File.read('./sizes.json'), symbolize_names: true)

  get '/' do
    File.read(File.join('public', 'index.html'))
  end

  # curl -XPOST -H "Content-Type: image/jpeg" --data-binary @/home/ubuntu/test.jpg http://localhost:9292/upload
  post '/upload' do
    unless params[:file] &&
           (tmpfile = params[:file][:tempfile]) &&
           (name = params[:file][:filename])
      halt 422, 'Nothing to upload!'
    end

    # TODO: see if file not already exist!

    begin
      s3 = AWS::S3.new(access_key_id: config[:access_key_id], secret_access_key: config[:secret_access_key], region: config[:region])
      bucket = s3.buckets[config[:bucket]]

      obj = bucket.objects["#{config[:path]}/#{name}"]
      if obj.exists?
        halt 409, "File already exists: '#{name}'"
      end
      obj.write(Pathname.new(tmpfile))

      sizes.values.each do |width, height|
        path_size = "#{config[:path]}/sizes/#{width}x#{height}"
        image = MiniMagick::Image.open(tmpfile.path)
        image.combine_options do |c|
          c.resize "#{width}x#{height}>"
          c.quality 85
        end
        tmpfile_size = Tempfile.new("#{name}.#{width}x#{height}")
        image.write tmpfile_size

        obj_size = bucket.objects["#{path_size}/#{name}"]
        obj_size.write(Pathname.new(tmpfile_size))

        #image.write "#{directory}/#{basename}"
      end

    rescue => error
      halt 500, { error: error.message }.to_json
    end

    return {
      filename: name,
      sizes: sizes.values.map {|size| size.join('x') }
    }.to_json
  end

end
