module Utils
  class CommandError < RuntimeError
    attr_accessor :command_output, :return_code

    def verbose_message
      if $verbose
        puts self.message
        puts '#'*20
        puts self.command_output
        puts '#'*20
        puts "Exit code: #{self.return_code}"
      end
    end
  end

  def command(cmd)
    puts "\t#{cmd}" if $verbose
    ret=''
    unless $dry
      ret = `#{cmd}`
      if $?.exitstatus != 0 ## return failure
        err=CommandError.new "Error Running:\t #{cmd}"
        err.command_output = ret
        err.return_code = $?.exitstatus
        raise err
      end
    end
    ret
  end

  def exit!(msg='Aborting')
    puts msg
    Kernel.exit 1
  end

end #module
