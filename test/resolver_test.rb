# Resolver tests for Inprovise
#
# Author::    Martin Corino
# License::   Distributes under the same license as Ruby

require_relative 'test_helper'

describe Inprovise::Resolver do
  before :each do
    @pkg_a = Inprovise::DSL.script('a') {}
    @pkg_b = Inprovise::DSL.script('b') {}
    @pkg_c = Inprovise::DSL.script('c') {}
    @pkg_d = Inprovise::DSL.script('d') {}
  end

  after :each do
    reset_script_index!
  end

  describe 'resolving a tree of script dependancies' do
    it 'resolves single scripts to a single script' do
      resolver = Inprovise::Resolver.new(@pkg_a)
      resolver.resolve
      resolver.scripts.must_equal [@pkg_a]
    end

    it 'resolves a chain of 2 scripts to a list of 2 scripts' do
      @pkg_a.depends_on(@pkg_b.name)
      resolver = Inprovise::Resolver.new(@pkg_a)
      resolver.resolve
      resolver.scripts.must_equal [@pkg_b, @pkg_a]
    end

    it 'resolves a chain of 3 scripts to a list of 3 scripts' do
      @pkg_a.depends_on(@pkg_b.name)
      @pkg_b.depends_on(@pkg_c.name)
      resolver = Inprovise::Resolver.new(@pkg_a)
      resolver.resolve
      resolver.scripts.must_equal [@pkg_c, @pkg_b, @pkg_a]
    end

    it 'resolves a tree of 3 scripts to a list of 3 scripts' do
      @pkg_a.depends_on(@pkg_b.name)
      @pkg_a.depends_on(@pkg_c.name)
      resolver = Inprovise::Resolver.new(@pkg_a)
      resolver.resolve
      resolver.scripts.must_equal [@pkg_b, @pkg_c, @pkg_a]
    end

    it 'resolves a tree of 4 scripts to a list of 4 scripts' do
      @pkg_a.depends_on(@pkg_b.name)
      @pkg_a.depends_on(@pkg_c.name)
      @pkg_c.depends_on(@pkg_d.name)
      resolver = Inprovise::Resolver.new(@pkg_a)
      resolver.resolve
      resolver.scripts.must_equal [@pkg_b, @pkg_d, @pkg_c, @pkg_a]
    end

    it 'errors out on circular dependancies' do
      @pkg_a.depends_on(@pkg_b.name)
      @pkg_b.depends_on(@pkg_a.name)
      resolver = Inprovise::Resolver.new(@pkg_a)
      assert_raises(Inprovise::Resolver::CircularDependencyError) { resolver.resolve }
    end
  end
end
