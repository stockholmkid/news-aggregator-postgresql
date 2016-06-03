require 'uri'
require 'pg'

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

class Article
  attr_reader :title, :url, :description, :errors

  def initialize(article_hash = {})
    @title = article_hash["title"]
    @url = article_hash["url"]
    @description = article_hash["description"]
    @errors = []
  end

  def self.all
    @articles = []
    article_db = db_connection { |conn| conn.exec("SELECT title, url, description FROM articles")}
    article_db.each do |article|
      new_article = Article.new(article)
      @articles << new_article
    end
      @articles
  end

  def valid?
    url_dup_check = db_connection { |conn| conn.exec("SELECT url FROM articles WHERE url = '#{url}'")}
    if title.strip.empty? || url.strip.empty? || description.strip.empty?
      @errors << "Please completely fill out form"
      return false
    elsif description.length < 20
      @errors << "Description must be at least 20 characters long"
      return false
    elsif !URI.parse(url).kind_of?(URI::HTTP) || !URI.parse(url).kind_of?(URI::HTTPS)
      @errors << "Invalid URL"
      return false
    elsif !url_dup_check.first.nil?
      @errors << "Article with same url already submitted"
      return false
    end
    return true
  end

end
