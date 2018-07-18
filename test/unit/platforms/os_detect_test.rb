# encoding: utf-8
require 'helper'
require 'train/transports/mock'

class OsDetectLinuxTester
  include Train::Platforms::Detect::Helpers::OSCommon
end

describe 'os_detect' do
  let(:detector) { OsDetectLinuxTester.new }

  def scan_with_files(uname, files)
    mock = Train::Transports::Mock::Connection.new
    mock.mock_command('uname -s', uname)
    mock.mock_command('uname -r', 'test-release')
    files.each do |path, data|
      mock.mock_command("test -f #{path}")
      mock.mock_command("test -f #{path} && cat #{path}", data)
    end
    Train::Platforms::Detect.scan(mock)
  end

  ## Detect all linux distros
  describe '/etc/enterprise-release' do
    it 'sets the correct family/release for oracle' do
      path = '/etc/enterprise-release'
      platform = scan_with_files('linux', { path => 'release 7' })

      platform[:name].must_equal('oracle')
      platform[:family].must_equal('redhat')
      platform[:release].must_equal('7')
    end
  end

  describe '/etc/redhat-release' do
    describe 'and /etc/os-release' do
      it 'sets the correct family, name, and release on centos' do
        files = {
          '/etc/redhat-release' => "CentOS Linux release 7.2.1511 (Core) \n",
          '/etc/os-release' => "NAME=\"CentOS Linux\"\nVERSION=\"7 (Core)\"\nID=\"centos\"\nID_LIKE=\"rhel fedora\"\n",
        }
        platform = scan_with_files('linux', files)
        platform[:name].must_equal('centos')
        platform[:family].must_equal('redhat')
        platform[:release].must_equal('7.2.1511')
      end
      it 'sets the correct family, name, and release on scientific linux' do
        files = {
          '/etc/redhat-release' => "Scientific Linux release 7.4 (Nitrogen)\n",
          '/etc/os-release' => "NAME=\"Scientific Linux\"\nVERSION=\"7.4 (Nitrogen)\"\nID=\"rhel\"\nID_LIKE=\"scientific centos fedora\"\nVERSION_ID=\"7.4\"\nPRETTY_NAME=\"Scientific Linux 7.4 (Nitrogen)\"\nANSI_COLOR=\"0;31\"\nCPE_NAME=\"cpe:/o:scientificlinux:scientificlinux:7.4:GA\"\nHOME_URL=\"http://www.scientificlinux.org//\"\nBUG_REPORT_URL=\"mailto:scientific-linux-devel@listserv.fnal.gov\"\n\nREDHAT_BUGZILLA_PRODUCT=\"Scientific Linux 7\"\nREDHAT_BUGZILLA_PRODUCT_VERSION=7.4\nREDHAT_SUPPORT_PRODUCT=\"Scientific Linux\"\nREDHAT_SUPPORT_PRODUCT_VERSION=\"7.4\"\n",
        }
        platform = scan_with_files('linux', files)
        platform[:name].must_equal('scientific')
        platform[:family].must_equal('redhat')
        platform[:release].must_equal('7.4')
      end
      it 'sets the correct family, name, and release on CloudLinux' do
        files = {
          '/etc/redhat-release' => "CloudLinux release 7.4 (Georgy Grechko)\n",
          '/etc/os-release' => "NAME=\"CloudLinux\"\nVERSION=\"7.4 (Georgy Grechko)\"\nID=\"cloudlinux\"\nID_LIKE=\"rhel fedora centos\"\nVERSION_ID=\"7.4\"\nPRETTY_NAME=\"CloudLinux 7.4 (Georgy Grechko)\"\nANSI_COLOR=\"0;31\"\nCPE_NAME=\"cpe:/o:cloudlinux:cloudlinux:7.4:GA:server\"\nHOME_URL=\"https://www.cloudlinux.com//\"\nBUG_REPORT_URL=\"https://www.cloudlinux.com/support\"\n",
        }
        platform = scan_with_files('linux', files)
        platform[:name].must_equal('cloudlinux')
        platform[:family].must_equal('redhat')
        platform[:release].must_equal('7.4')
      end
    end
  end

  describe 'darwin' do
    describe 'mac_os_x' do
      it 'sets the correct family, name, and release on os_x' do
        files = {
          '/System/Library/CoreServices/SystemVersion.plist' => '<string>Mac OS X</string>',
        }
        platform = scan_with_files('darwin', files)
        platform[:name].must_equal('mac_os_x')
        platform[:family].must_equal('darwin')
        platform[:release].must_equal('test-release')
      end
    end

    describe 'generic darwin' do
      it 'sets the correct family, name, and release on darwin' do
        files = {
          '/usr/bin/sw_vers' => "ProductVersion: 17.0.1\nBuildVersion: alpha.x1",
        }
        platform = scan_with_files('darwin', files)
        platform[:name].must_equal('darwin')
        platform[:family].must_equal('darwin')
        platform[:release].must_equal('17.0.1')
        platform[:build].must_equal('alpha.x1')
      end
    end
  end

  describe '/etc/debian_version' do
    def debian_scan(id, version)
      lsb_release = "DISTRIB_ID=#{id}\nDISTRIB_RELEASE=#{version}"
      files = {
        '/etc/lsb-release' => lsb_release,
        '/etc/debian_version' => '11',
      }
      scan_with_files('linux', files)
    end

    describe 'ubuntu' do
      it 'sets the correct family/release for ubuntu' do
        platform = debian_scan('ubuntu', '16.04')

        platform[:name].must_equal('ubuntu')
        platform[:family].must_equal('debian')
        platform[:release].must_equal('16.04')
      end
    end

    describe 'linuxmint' do
      it 'sets the correct family/release for linuxmint' do
        platform = debian_scan('linuxmint', '12')

        platform[:name].must_equal('linuxmint')
        platform[:family].must_equal('debian')
        platform[:release].must_equal('12')
      end
    end

    describe 'raspbian' do
      it 'sets the correct family/release for raspbian ' do
        files = {
          '/usr/bin/raspi-config' => 'data',
          '/etc/debian_version' => '13.6',
        }
        platform = scan_with_files('linux', files)

        platform[:name].must_equal('raspbian')
        platform[:family].must_equal('debian')
        platform[:release].must_equal('13.6')
      end
    end

    describe 'everything else' do
      it 'sets the correct family/release for debian ' do
        platform = debian_scan('some_debian', '12.99')

        platform[:name].must_equal('debian')
        platform[:family].must_equal('debian')
        platform[:release].must_equal('11')
      end
    end
  end

  describe '/etc/coreos/update.conf' do
    it 'sets the correct family/release for coreos' do
      lsb_release = "DISTRIB_ID=Container Linux by CoreOS\nDISTRIB_RELEASE=27.9"
      files = {
        '/etc/lsb-release' => lsb_release,
        '/etc/coreos/update.conf' => 'data',
      }
      platform = scan_with_files('linux', files)

      platform[:name].must_equal('coreos')
      platform[:family].must_equal('linux')
      platform[:release].must_equal('27.9')
    end
  end

  describe '/etc/os-release' do
    describe 'when not on a wrlinux build' do
      it 'fail back to genaric linux' do
        os_release = "ID_LIKE=cisco-unkwown\nVERSION=unknown"
        files = {
          '/etc/os-release' => os_release,
        }
        platform = scan_with_files('linux', files)

        platform[:name].must_equal('linux')
        platform[:family].must_equal('linux')
      end
    end

    describe 'when on a wrlinux build' do
      it 'sets the correct family/release for wrlinux' do
        os_release = "ID_LIKE=cisco-wrlinux\nVERSION=cisco123"
        files = {
          '/etc/os-release' => os_release,
        }
        platform = scan_with_files('linux', files)

        platform[:name].must_equal('wrlinux')
        platform[:family].must_equal('redhat')
        platform[:release].must_equal('cisco123')
      end
    end
  end

  describe 'qnx' do
    it 'sets the correct info for qnx platform' do
      platform = scan_with_files('qnx', {})

      platform[:name].must_equal('qnx')
      platform[:family].must_equal('qnx')
      platform[:release].must_equal('test-release')
    end
  end

  describe 'cisco' do
    it 'recognizes Cisco IOS12' do
      mock = Train::Transports::Mock::Connection.new
      mock.mock_command('show version', "Cisco IOS Software, C3750E Software (C3750E-UNIVERSALK9-M), Version 12.2(58)SE")
      platform = Train::Platforms::Detect.scan(mock)

      platform[:name].must_equal('cisco_ios')
      platform[:family].must_equal('cisco')
      platform[:release].must_equal('12.2')
    end

    it 'recognizes Cisco IOS XE' do
      mock = Train::Transports::Mock::Connection.new
      mock.mock_command('show version', "Cisco IOS Software, IOS-XE Software, Catalyst L3 Switch Software (CAT3K_CAA-UNIVERSALK9-M), Version 03.03.03SE RELEASE SOFTWARE (fc2)")
      platform = Train::Platforms::Detect.scan(mock)

      platform[:name].must_equal('cisco_ios_xe')
      platform[:family].must_equal('cisco')
      platform[:release].must_equal('03.03.03SE')
    end

    it 'recognizes Cisco Nexus' do
      mock = Train::Transports::Mock::Connection.new
      mock.mock_command('show version', "Cisco Nexus Operating System (NX-OS) Software\n  system:      version 5.2(1)N1(8b)\n")
      platform = Train::Platforms::Detect.scan(mock)

      platform[:name].must_equal('cisco_nexus')
      platform[:family].must_equal('cisco')
      platform[:release].must_equal('5.2')
    end
  end

  describe 'brocade' do
    it 'recognizes Brocade FOS-based SAN switches' do
      mock = Train::Transports::Mock::Connection.new
      mock.mock_command('version', "Kernel:     2.6.14.2\nFabric OS:  v7.4.2a\nMade on:    Thu Jun 29 19:22:14 2017\nFlash:      Sat Sep 9 17:30:42 2017\nBootProm:   1.0.11")
      platform = Train::Platforms::Detect.scan(mock)

      platform[:name].must_equal('brocade_fos')
      platform[:family].must_equal('brocade')
      platform[:release].must_equal('7.4.2a')
    end
  end
end
