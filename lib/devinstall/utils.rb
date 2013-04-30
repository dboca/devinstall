module Utils
  class CommandError < StandardError
    attr_accessor :command_output, :return_code
  end

  def command(cmd)
    puts cmd if $verbose
    ret=''
    unless $dry
      ret = `#{cmd}`
      if $?.exitstatus != 0 ## return failure
        puts "While executing:"
        puts cmd
        puts "The command failed with exitstatus #{$?.exitstatus}"
        puts "Full output of command follows"
        puts "="*40
        puts ret
        puts "="*40
        puts "Nothing to do. Aborting!"
        raise  CommandError("Error running").command_output(ret).return_code($?.exitstatus)
      end
    end
    ret
  end

  def exit! msg
    puts msg || "Aborting!"
    Kernel.exit 1
  end


end #module
