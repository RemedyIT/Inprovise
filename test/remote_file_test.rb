# Remote file tests for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

require_relative 'test_helper'

describe Inprovise::RemoteFile do
  before :each do
    @node = Inprovise::Infrastructure::Node.new('Node1', {host: 'host.address.net', channel: 'test', helper: 'test'})
    @log = Inprovise::Logger.new(@node, 'remote_file_test')
    @local_file_path = File.join(File.dirname(__FILE__), 'fixtures', 'example.txt')
    @remote_file_path = '/tmp/example.txt'
    @context = Inprovise::ExecutionContext.new(@node, @log, Inprovise::ScriptIndex.default)
    @local_file = Inprovise::LocalFile.new(@context, @local_file_path)
    @remote_file = Inprovise::RemoteFile.new(@context, @remote_file_path)
  end

  after :each do
    reset_infrastructure!
  end

  describe 'path' do
    it 'returns the absolute path of a local file' do
      @remote_file.path.must_equal @remote_file_path
    end
  end

  describe 'hash' do
    it 'returns the sha1 of a remote file' do
      @remote_file.hash.must_equal Digest::SHA1.hexdigest("RUN: sha1sum #{@remote_file.path}")
    end
  end

  describe 'matches' do
    it 'returns true if the passed file has a matching hash' do
      @node.helper.expects(:hash_for)
                  .with(@remote_file.path)
                  .returns(Digest::SHA1.hexdigest("RUN: sha1sum #{@remote_file.path}"))
      @remote_file.matches?(@remote_file).must_equal true
    end
  end

  describe 'exists?' do
    it 'checks if a file exists' do
      @node.helper.expects(:exists?)
                  .with(@remote_file.path)
                  .returns(true)
      @remote_file.exists?.must_equal true
    end

    it 'checks if a missing file exists' do
      @node.helper.expects(:exists?)
                  .with(@remote_file.path)
                  .returns(false)
      @remote_file.exists?.must_equal false
    end
  end

  describe 'copy_to' do
    it 'copies a file to another remote location' do
      @remote_destination = Inprovise::RemoteFile.new(@context, '/tmp/example-dest.txt')
      @node.helper.expects(:copy)
                  .with(@remote_file.path, @remote_destination.path)
                  .returns(nil)
      @remote_file.copy_to(@remote_destination).must_equal @remote_destination
    end

    it 'copies a file to local location by downlaoding it' do
      @local_destination = Inprovise::LocalFile.new(@context, "/tmp/example-#{Time.now.to_i}.txt")
      @node.helper.expects(:download)
                  .with(@remote_file.path, @local_destination.path)
                  .returns(nil)
      @remote_file.copy_to(@local_destination).must_equal @local_destination
    end
  end

  describe 'delete!' do
    it 'removes the file from the remote server' do
      @node.helper.expects(:delete)
                  .with(@remote_file.path)
                  .returns(nil)
      @remote_file.delete!
    end

    it "doesn't delete missing files" do
      @node.helper.expects(:exists?)
                  .with(@remote_file.path)
                  .returns(false)
      @node.helper.expects(:delete)
                  .with(@remote_file.path)
                  .never
      @remote_file.delete!
    end
  end

  describe 'set_permissions' do
    it 'sets permissions on the file based on a mask' do
      @node.helper.expects(:permissions)
                  .with(@remote_file.path)
                  .returns(0644)
      @remote_file.set_permissions(0644).must_equal @remote_file
      @remote_file.permissions.must_equal 0644
    end
  end
end
