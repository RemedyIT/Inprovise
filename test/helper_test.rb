# ScriptRunner  tests for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

require_relative 'test_helper'

describe Inprovise::CmdHelper do
  before :each do
    @node = Inprovise::Infrastructure::Node.new('myNode', {channel: 'test', helper: 'linux'})
  end

  after :each do
    reset_infrastructure!
  end

  describe 'helper' do

    describe 'platform specifics' do
      it 'provides appropriate administrator account' do
        @node.helper.admin_user.must_equal 'root'
      end

      it 'provides appropriate environment variable format' do
        @node.helper.env_reference('VAR').must_equal '$VAR'
      end
    end

    describe 'working directory' do
      it 'manages working directory' do
        @node.channel.expects(:run).with('pwd', false).returns('/root')
        @node.helper.cwd.must_equal '/root'
      end

      it 'returns old cwd on setting cwd' do
        @node.helper.set_cwd('/home/user').must_be_nil
        @node.helper.cwd.must_equal '/home/user'
        @node.helper.set_cwd('/root').must_equal '/home/user'
        @node.helper.cwd.must_equal '/root'
        @node.helper.set_cwd(nil).must_equal '/root'
        @node.channel.expects(:run).with('pwd', false).returns('/root')
        @node.helper.cwd.must_equal '/root'
      end
    end

    describe 'command execution' do
      it 'runs commands' do
        @node.channel.expects(:run).with('echo ok', false).returns('ok')
        @node.helper.run('echo ok').must_equal 'ok'
      end

      it 'runs sudo commands' do
        @node.channel.expects(:run).with('sudo sh -c "echo ok"', false).returns('ok')
        @node.helper.sudo.run('echo ok').must_equal 'ok'
      end

      it 'runs commands in cwd' do
        @node.helper.set_cwd('/home/user')
        @node.channel.expects(:run).with('cd /home/user; echo ok', false).returns('ok')
        @node.helper.run('echo ok').must_equal 'ok'
      end
    end

    describe 'file transfer' do
      it 'uploads files' do
        @node.channel.expects(:upload).with('/from/path', '/to/path')
        @node.helper.upload('/from/path', '/to/path')
      end

      it 'downloads files' do
        @node.channel.expects(:download).with('/from/path', '/to/path')
        @node.helper.download('/from/path', '/to/path')
      end

      it 'uploads files with changed cwd' do
        @node.helper.set_cwd('/home/user')
        @node.channel.expects(:upload).with('/from/path', '/home/user/to/path')
        @node.helper.upload('/from/path', 'to/path')
      end

      it 'downloads files with changed cwd' do
        @node.helper.set_cwd('/home/user')
        @node.channel.expects(:download).with('/home/user/from/path', '/to/path')
        @node.helper.download('from/path', '/to/path')
      end
    end

    describe 'file management' do

      it 'returns file content' do
        @node.channel.expects(:content).with('/file/path')
        @node.helper.cat('/file/path')
      end

      it 'returns file content from cwd' do
        @node.helper.set_cwd('/home/user')
        @node.channel.expects(:content).with('/home/user/file/path')
        @node.helper.cat('file/path')
      end

      it 'creates a directory' do
        @node.channel.expects(:run).with('mkdir -p /dir/path', false)
        @node.helper.mkdir('/dir/path')
      end

      it 'creates a directory from cwd' do
        @node.helper.set_cwd('/home/user')
        @node.channel.expects(:run).with('mkdir -p /home/user/dir/path', false)
        @node.helper.mkdir('dir/path')
      end

      it 'checks path existence' do
        @node.channel.expects(:exists?).with('/file/path').returns(true)
        @node.helper.exists?('/file/path').must_equal true
      end

      it 'check file existence' do
        @node.channel.expects(:file?).with('/file/path').returns(true)
        @node.helper.file?('/file/path').must_equal true
      end

      it 'checks directory existence' do
        @node.channel.expects(:directory?).with('/dir/path').returns(true)
        @node.helper.directory?('/dir/path').must_equal true
      end

      it 'copies files' do
        @node.channel.expects(:run).with("cp /from/path /to/path", false)
        @node.helper.copy('/from/path', '/to/path')
      end

      it 'moves files' do
        @node.channel.expects(:run).with("mv /from/path /to/path", false)
        @node.helper.move('/from/path', '/to/path')
      end

      it 'deletes files' do
        @node.channel.expects(:delete).with('/file/path')
        @node.helper.delete('/file/path')
      end

      it 'returns file permissions' do
        @node.channel.expects(:permissions).with('/file/path').returns(0755)
        @node.helper.permissions('/file/path').must_equal 0755
      end

      it 'sets file permissions' do
        @node.channel.expects(:set_permissions).with('/file/path', 0755)
        @node.helper.set_permissions('/file/path', 0755)
      end

      it 'returns file owner' do
        @node.channel.expects(:owner).with('/file/path').returns({ :user => 'me', :group => 'them'  })
        @node.helper.owner('/file/path').must_equal({ :user => 'me', :group => 'them'  })
      end

      it 'sets file owner' do
        @node.channel.expects(:set_owner).with('/file/path', 'me','them')
        @node.helper.set_owner('/file/path', 'me','them')
      end

    end

    describe 'shell utilities' do

      it 'echoes' do
        @node.channel.expects(:run).with('echo ok', false).returns('ok')
        @node.helper.echo('ok').must_equal 'ok'
      end

      it 'returns an environment variables value' do
        @node.channel.expects(:run).with('echo $HOME', false).returns('/home/user')
        @node.helper.env('HOME').must_equal '/home/user'
      end

      it 'returns an SHA1 hash for the file content' do
        @node.channel.expects(:run).with('sha1sum /file/path', false).returns('A1B2C3D4')
        @node.helper.hash_for('/file/path').must_equal 'A1B2C3D4'
      end

      it 'checks binary existence' do
        @node.channel.expects(:run).with('which ruby', false).returns('/usr/bin/ruby')
        @node.helper.binary_exists?('ruby').must_equal true
      end

    end

  end
end
