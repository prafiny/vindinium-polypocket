require 'rubygems'
require 'bundler'
require 'json'
require './bots/base_bot.rb'
require 'prettyprint'

Bundler.setup
Bundler.require

ROOT = File.dirname(__FILE__)
TAVERN = 0
AIR = -1
WALL = -2
AIM = {'North' => [-1, 0],
       'East'  => [0, 1],
       'South' => [1, 0],
       'West' => [0, -1]}

%w{models lib ext bots}.each do |dir|
  Dir[File.join(ROOT, dir, '**/*.{rb,so}')].each do |f|
    require f unless File.directory?(f)
  end
end

require './vindinium'
