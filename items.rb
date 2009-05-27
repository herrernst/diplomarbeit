#!/usr/local/bin/ruby

require 'rubygems'
require 'simple-rss'
require 'open-uri'
require 'hpricot'
require 'htmlentities'
require 'models.rb'

url = "http://news.google.de/news?output=rss&topc=h"
detail_url = "http://news.google.de/news?ncl=1302753357&output=rss"

rss = SimpleRSS.parse open(url)

coder = HTMLEntities.new

rss.items.each do |i|
  ncl=i.guid.match(/cluster=(\d+)/)[1].to_i
  fr = Hpricot(coder.decode(i.description))
  count = fr.search('//b:last').inner_text.sub(/\./,'').match(/\d+/)[0].to_i rescue next
  ii = Item.new
  ii.count = count
  ii.ncl = ncl
  ii.save!
end
