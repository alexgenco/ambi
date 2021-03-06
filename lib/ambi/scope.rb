require 'ambi/dsl'
require 'active_support/core_ext/string'

module Ambi
  class Scope
    class NoDomainError < RuntimeError; end;
    class NoAppError    < RuntimeError; end;

    class << self
      def dsls
        @dsls ||= [DSL::Endpoint, DSL::App, DSL::Domain].freeze
      end

      def levels
        @levels ||= [:endpoint, :app, :domain].freeze
      end

      def state
        @state ||= [
          :stack, :roots,
          :domain, :app,
          :name, :request_methods, :relative_path, :relative_path_requirements
        ].freeze
      end

      def auto_assign
        @auto_assign ||= state - \
          [:roots, :request_methods, :relative_path, :relative_path_requirements]
      end

      def normalize_request_methods(via)
        via.kind_of?(Symbol) ? [via] : via
      end

      def normalize_roots(roots)
        roots.respond_to?(:to_str) ? [roots] : roots
      end
    end

    def initialize(dsl, options = {}, &block)
      @dsl = dsl

      parent, roots, via, at, requirements = \
        options.values_at(:parent, :on, :via, :at, :requirements)

      @parent                         = parent
      @own_roots                      = Scope.normalize_roots(roots)
      @own_request_methods            = Scope.normalize_request_methods(via)
      @own_relative_path              = at 
      @own_relative_path_requirements = requirements
      
      Scope.auto_assign.each do |assign|
        instance_variable_set("@own_#{assign}".to_sym, options[assign])
      end

      instance_eval(&block) if block_given?

      self
    end

    def clean_room_parse(source)
      clean_room = CleanRoom.new(self, dsl)
      unless source.respond_to?(:to_str)
        message = '#clean_room_eval requires either a block or #to_str'
        raise ArgumentError, message
      end
      clean_room.instance_eval(source.to_str)
    end

    def clean_room_eval(&block)
      clean_room = CleanRoom.new(self, dsl)
      clean_room.instance_eval(&block) # if block_given?
    end

    def roots
      if own_roots.nil? && no_parent?
        message = ':roots must be defined on an app scope'
        raise ArgumentError, message
      end
      own_roots.nil? ? parent.roots : own_roots
    end

    def domain
      return own_domain unless own_domain.nil?

      if no_parent?
        message = ':domain must be defined standalone or in scope'
        raise NoDomainError, message
      end

      parent.domain
    end

    def app
      return own_app unless own_app.nil?

      if no_parent?
        message = ':app must be defined standalone or in scope'
        raise NoAppError, message
      end

      parent.app
    end

    def name(level = :domain, acc = [])
      parent.name(level, acc) unless no_parent?

      eligible_dsls = self.class.dsls[0..self.class.levels.index(level)]
      acc << own_name if own_name && eligible_dsls.include?(dsl)

      acc
    end

    def domain_stack
      stack(:domain)
    end

    def app_stack
      stack(:app)
    end

    def endpoint_stack
      stack(:endpoint)
    end

    def request_methods
      return own_request_methods unless own_request_methods.nil?
      no_parent? ? (parent || []) : parent.request_methods
    end

    def path
      parent_path = no_parent? ? '/' : parent.path

      c = [parent_path, own_relative_path].compact.collect(&:to_str)
      c.flatten.join.squeeze('/')
    end

    def path_requirements
      parent_path_requirements = \
        no_parent? ? {} : parent.path_requirements

      if own_relative_path_requirements.nil?
        return parent_path_requirements.to_hash
      end

      parent_path_requirements.merge(own_relative_path_requirements || {})
    end

    def inspect
      instance_variables =
        self.class.state.collect do |state|
          state = "own_#{state}".to_sym
          value = self.send(state)
          "@#{state}=#{value}" if value
        end
      "#<Ambi::Scope: @dsl=#{dsl},#{instance_variables.compact.join(',')}>"
    end

    protected

    attr_reader :dsl, :parent

    def no_parent?
      parent.nil?
    end

    def stack(level, acc = [])
      parent.stack(level, acc) unless no_parent?

      if (dsl == "Ambi::DSL::#{level.to_s.camelize}".constantize)
        acc.concat(own_stack || [])
      end

      acc
    end

    state.each { |state| attr_reader "own_#{state}".to_sym }
  end
end
