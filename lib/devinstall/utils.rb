module Utils

  def command(cmd)
    puts cmd if $verbose
    ret=''
    unless $dry
      ret = `#{cmd}` unless $dry
      if $?.exitstatus != 0 ## return failure
        puts "While executing:"
        puts cmd
        puts "The command failed with exitstatus #{$?.exitstatus}"
        puts "Full output of command follows"
        puts "="*40
        puts ret
        puts "="*40
        puts "Nothing to do. Aborting!"
        exit! 1
      end
    end
    ret
  end

  def exit! msg
    puts msg || "Aborting!"
    Kernel.exit 1
  end


end #module
