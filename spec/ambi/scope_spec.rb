require 'spec_helper'

module Ambi
  describe Scope do 
    let(:parent) { Scope.new(DSL::Domain) }
    let(:child)  { Scope.new(DSL::App, parent: parent) }

    describe 'domain via #own_domain/#derived_domain' do
      it 'raises an error if neither explicitly set nor inherited' do
        expect {
          child.derived_domain
        }.to raise_error(Scope::NoDomainError)
      end

      it 'inherits if not explicitly set' do
        parent.instance_variable_set(:@own_domain, :'otherblog.org')
        child.derived_domain.should == :'otherblog.org'
      end

      it 'overrides if explicitly set' do
        parent.instance_variable_set(:@own_domain, :'myblog.com')
        child.instance_variable_set(:@own_domain, :'otherblog.org')
        child.derived_domain.should == :'otherblog.org'
      end
    end

    describe 'app via #own_app/#derived_app' do
      it 'raises an error if neither explicitly set nor inherited' do
        expect {
          child.derived_app
        }.to raise_error(Scope::NoAppError)
      end

      it 'inherits if not explicitly set' do
        parent.instance_variable_set(:@own_app, :entries)
        child.derived_app.should == :entries
      end

      it 'overrides if explicitly set' do
        parent.instance_variable_set(:@own_app, :entries)
        child.instance_variable_set(:@own_app, :comments)
        child.derived_app.should == :comments
      end
    end

    describe 'request method access via #own_request_methods/#derived_request_methods' do
      it 'inherits if not explicitly set' do
        parent.instance_variable_set(:@own_request_methods, [:get])
        child.derived_request_methods.should == [:get]
      end

      it 'overrides if explicitly set' do
        parent.instance_variable_set(:@own_request_methods, [:get])
        child.instance_variable_set(:@own_request_methods, [:post])
        child.derived_request_methods.should == [:post]
      end
    end

    describe 'path matcher via #own_relative_path_matcher/#derived_path_matcher' do
      it 'accepts a string' do
        parent.instance_variable_set(:@own_relative_path_matcher, '/foo')
        parent.derived_path_matcher.should match('/foo')
      end

      it 'accepts a regular expression' do
        parent.instance_variable_set(:@own_relative_path_matcher, %r{/[a-z]+})
        parent.derived_path_matcher.should match('/foo')
        parent.derived_path_matcher.should_not match('/123')
      end

      it 'defaults to an optional forward slash' do
        parent.derived_path_matcher.should match('/')
        parent.derived_path_matcher.should match('')
        parent.derived_path_matcher.should_not match('something else')
      end

      it 'builds from parent (by appending)' do
        parent.instance_variable_set(:@own_relative_path_matcher, %r{/foo/?})
        child.instance_variable_set(:@own_relative_path_matcher, '/bar')
        child.derived_path_matcher.should match('/foo/bar')
        child.derived_path_matcher.should_not match('/foo/will')
      end
    end
  end
end