class ApplicationController < Sinatra::Base
  
  # set folder for templates to ../views, but make the path absolute
  set :views, "app/views"

  # 不加这行找不到静态资源
  set :public_folder, 'public' 

  # 分页
  # 也可以 include WillPaginate::Sinatra::Helpers
  register WillPaginate::Sinatra

  get '/' do
    @weibos = Weibo.where(active: true).order(released_at: :desc).paginate(page: params[:page], per_page: 10)
    session[:hello] = "hello world!"
    erb :index
  end

  get '/:id/large_pic' do
    @weibo = Weibo.find_by_id(params[:id])
    redirect to('/') if @weibo.nil?
    erb :large
  end

  get '/:id/all_pics' do
    @weibo = Weibo.find_by_id(params[:id])
    redirect to('/') if @weibo.nil?
    erb :all_pics
  end
end