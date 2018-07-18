# encoding: utf-8

require 'helper'
require 'train/transports/ssh'

describe 'CiscoIOSConnection' do
  let(:cls) do
    Train::Platforms::Detect::Specifications::OS.load
    plat = Train::Platforms.name('mock').in_family('cisco_ios')
    plat.add_platform_methods
    plat.stubs(:cisco_ios?).returns(true)
    Train::Platforms::Detect.stubs(:scan).returns(plat)
    Train::Transports::SSH
  end

  let(:opts) do
    {
      host: 'fakehost',
      user: 'fakeuser',
      password: 'fakepassword',
    }
  end

  let(:connection) do
    cls.new(opts).connection
  end

  describe '#initialize' do
    it 'provides a uri' do
      connection.uri.must_equal 'ssh://fakeuser@fakehost:22'
    end
  end

  describe '#unique_identifier' do
    it 'returns the correct identifier' do
      output = "NAME: \"Chassis\", DESCR: \"Cisco 7206VXR, 6-slot chassis\"\r\nPID: CISCO7206VXR      , VID:    , SN: 4279256517 \r\n\r\nNAME: \"NPE400 0\", DESCR: \"Cisco 7200VXR Network Processing Engine NPE-400\"\r\nPID: NPE-400           , VID:    , SN: 11111111   \r\n\r\nNAME: \"module 0\", DESCR: \"I/O FastEthernet (TX-ISL)\"\r\nPID: C7200-IO-FE-MII/RJ45=, VID:    , SN: 4294967295 \r\n\r\nNAME: \"Power Supply 1\", DESCR: \"Cisco 7200 AC Power Supply\"\r\nPID: PWR-7200-AC       , VID:    , SN:            \r\n\r\nNAME: \"Power Supply 2\", DESCR: \"Cisco 7200 AC Power Supply\"\r\nPID: PWR-7200-AC       , VID:    , SN:            "
      Train::Transports::SSH::CiscoIOSConnection.any_instance
        .expects(:run_command_via_connection).with('show inventory')
        .returns(OpenStruct.new(stdout: output))
      connection.unique_identifier.must_equal('4279256517')
    end
  end

  describe '#format_result' do
    it 'returns correctly when result is `good`' do
      output = 'good'
      Train::Extras::CommandResult.expects(:new).with(output, '', 0)
      connection.send(:format_result, 'good')
    end

    it 'returns correctly when result matches /Bad IP address/' do
      output = "Translating \"nope\"\r\n\r\nTranslating \"nope\"\r\n\r\n% Bad IP address or host name\r\n% Unknown command or computer name, or unable to find computer address\r\n"
      Train::Extras::CommandResult.expects(:new).with('', output, 1)
      connection.send(:format_result, output)
    end

    it 'returns correctly when result matches /Incomplete command/' do
      output = "% Incomplete command.\r\n\r\n"
      Train::Extras::CommandResult.expects(:new).with('', output, 1)
      connection.send(:format_result, output)
    end

    it 'returns correctly when result matches /Invalid input detected/' do
      output = "             ^\r\n% Invalid input detected at '^' marker.\r\n\r\n"
      Train::Extras::CommandResult.expects(:new).with('', output, 1)
      connection.send(:format_result, output)
    end

    it 'returns correctly when result matches /Unrecognized host/' do
      output = "Translating \"nope\"\r\n% Unrecognized host or address, or protocol not running.\r\n\r\n"
      Train::Extras::CommandResult.expects(:new).with('', output, 1)
      connection.send(:format_result, output)
    end
  end

  describe '#format_output' do
    it 'returns the correct output' do
      cmd = 'show calendar'
      output = "show calendar\r\n10:35:50 UTC Fri Mar 23 2018\r\n7200_ios_12#\r\n7200_ios_12#"
      result = connection.send(:format_output, output, cmd)
      result.must_equal '10:35:50 UTC Fri Mar 23 2018'
    end

    it 'returns the correct output when a pipe is used' do
      cmd = 'show running-config | section line con 0'
      output = "show running-config | section line con 0\r\nline con 0\r\n exec-timeout 0 0\r\n privilege level 15\r\n logging synchronous\r\n stopbits 1\r\n7200_ios_12#\r\n7200_ios_12#"
      result = connection.send(:format_output, output, cmd)
      result.must_equal "line con 0\r\n exec-timeout 0 0\r\n privilege level 15\r\n logging synchronous\r\n stopbits 1"
    end
  end
end
