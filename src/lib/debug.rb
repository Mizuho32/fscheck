#!/usr/bin/env ruby
# coding:utf-8

$DEBUG = true

$imagepath = ARGV[0] || "../../image/fs.img"
$image = File.binread($imagepath)

loop do
  load 'maintest.rb'
  puts "\n"*3
  $stdin.gets
end
