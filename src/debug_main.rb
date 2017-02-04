require 'test/unit/testresult'
require 'test/unit/ui/console/testrunner'
load 'types.rb'
load 'maintest.rb'

$fs = FileSystem.load_xv6_fs(fsimg: $image, block_size: 512, definition: {superblock: 1..1, inodeblock: 32..57})

Init.init()
Test::Unit::AutoRunner.run
#Report.report()
#pp $result
