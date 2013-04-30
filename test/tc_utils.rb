require './lib/devinstall/utils'
require "test/unit"
# test command('ls')
include Utils

class TestCommand < Test::Unit::TestCase
  def test_ls_ok
    assert_nothing_raised("Command = ls") do
      command "ls"
    end
  end
  def test_ls_nodir # should raise an error
    assert_raises do
      command "ls /xyz"
    end
  end
end
