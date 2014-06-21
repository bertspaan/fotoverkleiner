# encoding: utf-8

require 'sinatra'
require 'json'

class Fotoverkleiner < Sinatra::Base
  config = JSON.parse(File.read('/var/www/fotoverkleiner/shared/config.json'), symbolize_names: true)
  #config = JSON.parse(File.read('./config.json'), symbolize_names: true)
  sizes = JSON.parse(File.read('./sizes.json'), symbolize_names: true)

  Aws.config = {access_key_id: config[:access_key_id], secret_access_key: config[:secret_access_key], region: config[:region]}
  s3 = Aws::S3.new

  before do
    content_type 'text/html; charset=utf-8'
  end

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
      #s3 = AWS::S3.new(access_key_id: config[:access_key_id], secret_access_key: config[:secret_access_key], region: config[:region])
      #bucket = s3.buckets[config[:bucket]]

      tmpfile.binmode
      resp = s3.put_object(
        :bucket => config[:bucket],
        :key => "#{config[:path]}/#{name}",
        :body => tmpfile.read
      )

      sizes.values.each do |width, height|
        path_size = "#{config[:path]}/sizes/#{width}x#{height}"
        image = MiniMagick::Image.open(tmpfile.path)
        image.combine_options do |c|
          c.resize "#{width}x#{height}>"
          c.quality 85
        end
        tmpfile_size = Tempfile.new("#{name}.#{width}x#{height}")
        image.write tmpfile_size
        tmpfile_size.binmode

        tmpfile_size.rewind
        resp = s3.put_object(
          :bucket => config[:bucket],
          :key => "#{path_size}/#{name}",
          :body => tmpfile_size.read
        )

        # Write resized image to disk locally (for testing):
        #image.write "/Users/bert/Downloads/#{name}.#{width}x#{height}.jpg"
      end

    rescue => error
      halt 500, { error: error.message }.to_json
    end

    content_type :json
    return {
      filename: name,
      sizes: sizes.values.map {|size| size.join('x') }
    }.to_json
  end

end
