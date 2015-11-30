require 'spec_helper'

describe Conjur::DSL2::Visitor do
  class Foo; end
  class Bar; end
  class BlahBlah; end
  module HooHah ; end
  class Inc
    include HooHah
  end
  class Super ; end
  class Sub < Super ; end
  class Baz
    def each
      yield Foo.new
      yield Bar.new
      yield BlahBlah.new
      yield Inc.new
      yield Sub.new
    end
  end

  class Target
    attr_reader :visited
    attr_accessor :visitor

    def initialize
      @visited = []
      @visitor = Conjur::DSL2::Visitor.new(self)
    end
    def visit_foo foo
      @visited << 'foo'
    end
    def visit_bar bar
      @visited << 'bar'
    end
    def visit_blah_blah blah
      @visited << 'blah_blah'
    end
    def visit_baz baz
      @visited << 'baz'
      baz.each do |o|
        visitor.visit o
      end
    end
    def visit_hoo_hah o
      @visited << 'hoo_hah'
    end
    def visit_super o
      @visited << 'super'
    end
  end

  subject do
    Target.new
  end

  describe '#visit' do
    before do
      subject.visitor.visit Baz.new
    end

    context 'when methods are defined' do
      it 'visits each object correctly' do
        expect(subject.visited).to eq(%w(baz foo bar blah_blah hoo_hah super))
      end
    end

    context 'when visit methods are not defined' do
      it 'raises no method error' do
        expect{ subject.visit(Object.new) }.to raise_exception(NoMethodError)
      end
    end
  end

end