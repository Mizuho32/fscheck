module Report
  class << self
    def init
      Kernel.puts "INIT"
      @report = ""
    end

    def puts(str, color=nil)

      @report << %Q{<pre class="#{color}">}

      case(color)
        when :red then
          print("\e[91m")
        when :blue then
          print("\e[94m")
        when :cyan then
          print("\e[96m")
        when :green then
          print("\e[92m")
        when :yellow then
          print("\e[93m")
        when :orange then
        when :purple then
        when :pink then
          print("\e[95m")
      end

      Kernel.puts(str)
      @report << str + "</pre>\n"

      print "\e[0m"
    end

    def report
      #Kernel.puts @report

      path = File.dirname($imagepath)
      name = File.basename($imagepath, ".img")

      repo = <<-"REPO"
<!DOCTYPE html>

<html>
	<head>
		<meta charset="utf-8">
		<title>#{name}</title>
    <style>
      :root{
        --red:    #fb0000;
        --blue:   #0032fb;
        --cyan:   #00e0fb;
        --green:  #00fb23;
        --yellow: #ffed56;
        --orange: #ff8056;
        --purple: #c856ff;
        --pink:   #ff56b9;
      }
      .red{ color: var(--red);}
      .blue{ color: var(--blue);}
      .cyan{ color: var(--cyan);}
      .green{ color: var(--green);}
      .yellow{ color: var(--yellow);}
      .orange{ color: var(--orange);}
      .purple{ color: var(--purple);}
      .pink{ color: var(--pink);}
      .console{ background-color: #000; }
    </style>
	</head>
	<body>
    <div class="console">
    #{@report}
    </div>
    <h2> structure </h2>
    <pre>
All bitmap flag
#{Init.bitmap_use}

All block use from inodes
#{$fs.inodeblocks.map{|inode| inode.all_using_blocks}.flatten}

Inodes:
#{Init.used_from_inode.map{|inode, all_addrs|
  inode.to_s + "all addrs:\n#{all_addrs}"
}.join("\n\n")}

Dirs:
#{
  Init.used_from_inode.keys
    .select{|inode| inode.type == FileSystem::DinodeBlockChunk::T_DIR}
    .map{|inode| 
      "inum: #{inode.inode_index}\n" +
      inode.all_addrs.map{|block_index|
        $fs[block_index].select{|file| !file.inum.zero?}.map{|file|
          "\t#{file.inum}: #{file.name}"
        }.join("\n")
      }.join("\n")
    }.join("\n")
}
    <pre>
  </body>
</html>
REPO
      #Kernel.puts repo
      File.write(path + "/html/" + name + ".html", repo)
    end
  end
end
          
