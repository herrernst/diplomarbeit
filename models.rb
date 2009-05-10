require 'rubygems'
require 'datamapper'

require 'password.rb'


class Item
  include DataMapper::Resource

  property :id, Serial
  property :ncl, Integer
  property :count, Integer

  has n, :keywords
  timestamps :created_at

  def link
    "http://news.google.de/news?ncl=#{@ncl}&output=rss"
  end

end

class Keyword
  include DataMapper::Resource
  belongs_to :item

  property :id, Serial
  property :word, String

end

DataMapper.auto_upgrade!
