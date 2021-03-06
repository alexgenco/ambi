module Support
  module RouteHelpers
    def mock_route(name, path, request_methods, path_requirements)
      options = {
        domain: :'myblog.com', app: :entries, on: ['/foo', '/bar'],
        at: path, via: request_methods, requirements: path_requirements
      }
      scope = ::Ambi::Scope.new(::Ambi::DSL::App, options)
      ::Ambi::Route.new(scope, name)
    end
  end
end
