require 'test/unit'

module Report
  class << self
    def init
      @report = ""
    end


    def catch(name, &block)
      begin
        block.call
      rescue Test::Unit::AssertionFailedError => failure
        puts_report(failure.to_s.gsub(?<, "&lt;").gsub(?>, "&gt;"), :bold)
        puts_report(name[/test: (.+)/, 1] + " failed\n", :red)
        raise failure
      end
    end

    def puts_report(str, color=nil)
      @report << %Q{<pre class="#{color}">#{str}</pre>\n}
      #@report << str + "</pre>\n"
    end

    def puts_color(str, color=nil)
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
        when :bold then
          print("\e[97m")
      end

      Kernel.puts(str)

      print "\e[0m"
    end

    def puts(str, color=nil)
      puts_report(str, color)
      puts_color(str, color)
    end

    def all_report(results, fullpath)
       repo = <<-"REPO"
<!DOCTYPE html>

<html>
	<head>
		<meta charset="utf-8">
		<title>#{name}</title>
    <style type="text/css">
      :root{
        --red:    #fb0000;
        --blue:   #0032fb;
        --cyan:   #00e0fb;
        --green:  #00fb23;
        --yellow: #ffed56;
        --orange: #ff8056;
        --purple: #c856ff;
        -failures-pink:   #ff56b9;
        --black:  #000;
        --white:  #fff;

      }
      .red{ color: var(--red);}
      .blue{ color: var(--blue);}
      .cyan{ color: var(--cyan);}
      .green{ color: var(--green);}
      .yellow{ color: var(--yellow);}
      .orange{ color: var(--orange);}
      .purple{ color: var(--purple);}
      .pink{ color: var(--pink);}
      .black{ color: var(--black);}
      .white{ color: var(--white);}
      .console{ background-color: #000; }
      .bold{ 
        color: var(--white);
        font-weight: bold; 
      }
      a:link { color: #bbfffd; }
      a:visited { color: #f1b2ff; }
      a:hover { color: #fff; }
    </style>
	</head>
	<body>
    <h2>Test Result</h2>
    <div class="console">
    #{
      Hash[results.sort].map{|img, result|
        <<-"IMG"
<div>
  <h2 class="white"><a href="#{File.basename(img, ".img")+".html"}">#{img}</a></h2>
#{
  result.failures.map{|failure|
    <<-"FAI"
<pre class="yellow">
#{failure.method_name}
</pre>
<pre class="red">
#{failure.message.gsub(?<, "&lt;").gsub(?>, "&gt;")}
</pre>
<pre class="bold">
#{failure.location.join("\n")}
</pre>
</br>
    FAI
  }.join("\n")
}

  <pre class="cyan">#{result.assertion_count} assertions, #{result.failures.size} failures</pre>
  </br>
</div>
IMG
      }.join("\n")
    }
    </div>
  </body>
</html>
REPO
      #Kernel.puts repo
      File.write(fullpath, repo)
     
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
        --black:  #000;
        --white:  #fff;

      }
      .red{ color: var(--red);}
      .blue{ color: var(--blue);}
      .cyan{ color: var(--cyan);}
      .green{ color: var(--green);}
      .yellow{ color: var(--yellow);}
      .orange{ color: var(--orange);}
      .purple{ color: var(--purple);}
      .pink{ color: var(--pink);}
      .black{ color: var(--black);}
      .white{ color: var(--white);}
      .console{ background-color: #000; }
      .bold{ 
        color: var(--white);
        font-weight: bold; 
      }
    </style>
	</head>
	<body>
    <h2>Test Result</h2>
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
      @report = ""
    end
  end
end
          
