require 'active_support'
require 'active_support/core_ext'
require 'active_support/inflector'
require 'erb'
require_relative './session'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res) #Already Rack::Request and Rack::Response
    @req = req
    @res = res
    @already_built_response = false
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    raise "Cannot redirect twice" if already_built_response?

    @res.header["location"] = url
    @res.status = 302

    @already_built_response = true

    session.store_session(@res)
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    raise "Cannot render twice" if already_built_response?

    @res.write(content)
    @res['Content-Type'] = content_type

    @already_built_response = true

    @session.store_session(@res)
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    raise "Cannot render twice" if already_built_response?
    controller_name = ("#{self.class}").underscore
    content = File.read("views/#{controller_name}/#{template_name}.html.erb")
    render_content(ERB.new(content).result(binding), 'text/html')
    @already_built_response = true
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(name) ####
    render(name) unless @already_built_response
  end
end
