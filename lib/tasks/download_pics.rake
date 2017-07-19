task :download_pics do
  require 'rest-client'
  require 'nokogiri'
  require "open-uri"
  require './app/models/weibo.rb'

  ActiveRecord::Base.establish_connection(
    :adapter  => 'sqlite3',
    :pool => 50,
    :database => './db/weibo.sqlite'
  )

  def download_pics(weibo)
    cookies = YAML::load_file('config/config.yml')['weibo_cookie']
    dic_name = "public/combination_pics/#{weibo.id}"
    Dir.mkdir(dic_name) unless File.exists?(dic_name)
    url = weibo.pic_combination_url
    html = RestClient.get(url,{ cookies: cookies })

    i = 0
    count = 0

    doc = Nokogiri::HTML(html.body)
    doc.xpath("//img").each do |content|
      content.to_s.match(/src="(.*)sinaimg(.*)\" alt.*/)
      tem_url = ($1 + "sinaimg" + $2).sub('thumb180', 'large')
      pic_name = "public/combination_pics/#{weibo.id}/#{i}.jpg"
      if File.exists?(pic_name)
        p '图像已存在'
        weibo.update(pics_downloaded?: true)
        next 
      end
      open(tem_url) {|f|
         File.open(pic_name, "wb") do |file|
           file.puts f.read
         end
         p "已下载#{count}张图片"
         count += 1
      }
      i += 1
      weibo.update(pics_downloaded?: true)
    end
    i = 0
  end

  begin
    threads = Weibo.where.not(pic_combination_url: nil).where(pics_downloaded?: false).map do |record|
      Thread.new do
        download_pics record
      end
    end

    threads.each(&:join)
  rescue RestClient::Exceptions::Timeout
    p "超时异常"
  end
end