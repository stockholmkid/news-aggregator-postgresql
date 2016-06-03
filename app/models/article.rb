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
    url_test = @url =~ URI::regexp
    url_dup_check = db_connection { |conn| conn.exec("SELECT url FROM articles WHERE url = '#{url}'")}
    if title.strip.empty? || url.strip.empty? || description.strip.empty?
      @errors << "Please completely fill out form"
    end
    if description.length < 20 && description.length > 0
    @errors << "Description must be at least 20 characters long"
    end
    if url_test.nil? && url.strip.length > 0
      @errors << "Invalid URL"
    end
    if !url_dup_check.first.nil?
      @errors << "Article with same url already submitted"
    end
    if @errors.empty?
      return true
    else
      return false
    end
  end

  def save
    if valid?
      db_connection do |conn|
        conn.exec_params("INSERT INTO articles (title, url, description) VALUES ($1, $2, $3)", [title, url, description])
      end
      return true
    else
      return false
    end
  end

end
