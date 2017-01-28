#!/usr/bin/env ruby
# coding:utf-8

$DEBUG = true

$image = File.binread(ARGV[0] || "../../image/fs.img")

loop do
  load 'maintest.rb'
  puts "\n"*3
  $stdin.gets
end
