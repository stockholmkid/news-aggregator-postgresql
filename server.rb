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

  @articles = db_connection { |conn| conn.exec("SELECT title, url, description FROM articles")}
  erb :articles
end

get "/articles/new" do
  erb :post_articles
end

post "/articles/new" do
  title = params['title']
  url = params['url']
  description = params['description']
    db_connection do |conn|
      conn.exec_params("INSERT INTO articles (title, url, description) VALUES ($1, $2, $3)", [title, url, description])
    end

  redirect "/articles"
end
