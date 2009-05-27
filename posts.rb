#!/usr/local/bin/ruby

require 'rubygems'
require 'dm-core'
require 'open-uri'
require 'json'
require 'hpricot'
require 'iconv'
require 'simple-rss'
require 'htmlentities'

require 'models.rb'

VERBOSE=true

def update_blogs

  url = "http://deutscheblogcharts.de/archiv/2009-20.html"
  res=open(url).read
  doc=Hpricot(res)
  doc.search("/html/body/table/tbody/tr").each_with_index do |tr, i|
    uri = tr.at("td[3] a[3]").inner_text
    blog = Blog.first(:uri => uri) || Blog.new(:uri => uri)
    puts blog.title = tr.at("td[3] a[1] b").inner_text
    pos = tr.at("td[1]").inner_text.to_i
    raise "weird" unless pos-1 == i
    blog.save!
  end

  puts "UPDATE DONE"

end #update_blogs

def get_rss
  coder = HTMLEntities.new
  blogs = Blog.all
  puts "Updating #{blogs.length} Blogs"
  threads = []
  blogs.each do |blog|
    if blog.feed_uri.nil?
      raise "Blog #{blog.title} hat keinen RSS-Feed." rescue $stderr.puts $!
      next
    end
#    threads << Thread.new(blog) do |blog| ##############uncomment for threading
      puts "----------"   
      puts "Processing #{blog.feed_uri}..."
      begin
        res = open(blog.feed_uri)
        header_charset = res.charset
        m = res.readline.match(/encoding=('|")([A-Za-z0-9\-]+)('|")/)
 	res.rewind
        body_charset = if m && m[2]
	    m[2]
	else
	    nil
	end
	charset = header_charset || body_charset
	con = Iconv.conv('utf-8', charset, res.read)
        feed_xml=con
      rescue OpenURI::HTTPError, Timeout::Error, SystemCallError => e
        $stderr.puts "Feed #{blog.feed_uri} kann nicht geholt werden (#{e})"
        next
      end
      begin
        feed = SimpleRSS.parse(feed_xml)
        raise "Feed ist nil (#{e})" if feed.nil?
      rescue Exception => e
        $stderr.puts "Feed #{blog.feed_uri} kann nicht geparsed werden (#{e})"
        next
      ensure
      end
      feed.entries.each do |entry|
        en=Post.first(:guid => entry.guid)||Post.new
        en.title=coder.decode(entry.title)
        en.url=entry.link
        en.content=coder.decode(entry.description).gsub(/<[^<]+>/,'') if entry.description
#        en.content=entry.description
        en.guid=entry.guid
        en.date_published = entry.pubDate
        en.blog=blog
        en.save rescue $stderr.puts "Saving failed!!!!!! for an item of #{blog.feed_uri} (#{$!})"
      end
#      puts "Finished #{blog.title}."
#    end ##############uncomment for threading
    
  end
  threads.each { |aThread|  aThread.join }
  
end


#update_blogs
get_rss
