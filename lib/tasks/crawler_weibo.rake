task :crawler_weibo do
  Dir.mkdir('./public/pictures') unless Dir.exist?('./public/pictures')
  Dir.mkdir('./public/combination_pics') unless Dir.exist?('./public/combination_pics')

  ActiveRecord::Base.establish_connection(
    :adapter  => 'sqlite3',
    pool: 50,
    :database => './db/weibo.sqlite'
  )

  # 把微博后缀时间转换为Time格式
  def parse_time(time)
    return (Time.now - $1.to_i.minutes) if time.match(/(\d*)分钟前/)
    return $1.to_time if time.match(/今天 ([\d|:]*)/)
    return  ([Time.now.year.to_s, $1, $2].join('-') + ' ' + $3).to_time if time.match(/(\d*)月(\d*)日 ([\d|:]*)/)
  end


  def get_weibo page, latest_time

    cookies = YAML::load_file('config/config.yml')['weibo_cookie']

    url = "https://weibo.cn/?page=#{page}"
    html = RestClient.get(url,{ cookies: cookies })
    doc = Nokogiri::HTML(html.body)

    # 这句话很重要
    contents = doc.xpath('//div[contains(@id, "M_") and @class="c"]')

    contents.each_with_index do |content, index|
      # 发布时间
      release_time = parse_time(content.xpath('.//span[@class="ct"]').text)

      if release_time <= latest_time + 30.seconds
        p "第#{page}页从第#{index}条开始是之前已抓取的"
        break
      end

      # 维护一个最新的发布时间
      REDIS.set(:temp_time, release_time) if release_time > (REDIS.get(:temp_time).to_time + 30.seconds)

      # 文字
      sentence = content.xpath('.//span[@class="ctt"]').text
      sentence = sentence[1..-1] if sentence.match(/^:/)

      # 有秒拍视频的不用抓取，当前我们的朋友圈不支持发视频
      next if sentence.match(/秒拍视频|广场/)

      # 图url
      pic_url = ($1 + 'sinaimg' + $2).sub('wap180', 'large') if content.to_s.match(/src=\"(.*)sinaimg(.*)\" alt=\"图片\"/) # wap180缩略图 large原图

      # 组图url
      temp_url = ($1 + 'picAll' + $2) if content.to_s.match(/.*href=\"(.*)picAll(.*)\"/)

      weibo = Weibo.create(content: sentence , pic_url: pic_url, pic_combination_url: temp_url, released_at: release_time.strftime("%Y-%m-%d %H:%M:%S"))

      # 下载预览图
      if pic_url
        begin
          open(pic_url) {|f|
             File.open("./public/pictures/#{weibo.id}.jpg","wb") do |file|
               file.puts f.read
             end
          }
        rescue
          p "图片(#{pic_url})下载失败"
        end
      end

      p "第#{page}页 第#{index}条微博抓取完毕, 发布时间#{release_time.strftime("%Y-%m-%d %H:%M:%S")}"
    end
  end


 
  begin
    REDIS.set(:temp_time, (Time.now - 5.hours)) if REDIS.get(:temp_time).nil?
    threads = (1..10).map do |page|
      Thread.new do
        get_weibo page, REDIS.get(:temp_time).to_time
      end
    end
    threads.each(&:join)
    p '-' * 50
    p '本轮抓取完毕'
  rescue RestClient::Exceptions::Timeout
    p '超时异常'
  end
end