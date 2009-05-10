require 'rubygems'
require 'datamapper'

require 'password.rb'


class Item
  include DataMapper::Resource

  property :id, Integer, :key => true
  property :count, Integer

end

DataMapper.auto_upgrade!
