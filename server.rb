require "sinatra"
require "pg"
require_relative "./app/models/article"
require 'pry'
set :views, File.join(File.dirname(__FILE__), "app", "views")

configure :development do
  set :db_config, { dbname: "news_aggregator_development" }
end

configure :test do
  set :db_config, { dbname: "news_aggregator_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

get "/articles" do

  @articles = Article.all
  erb :articles
end

get "/articles/new" do
  erb :post_articles
end

post "/articles/new" do
  @title = params['title']
  @url = params['url']
  @description = params['description']
  new_article = Article.new({"title" => @title, "url" => @url, "description" => @description})
  if !new_article.valid?
    @error = new_article.errors
    erb :post_articles
  else
    new_article.save
    redirect "/articles"
  end
end
