#!/usr/bin/env ruby

require 'rubygems'
require 'webrick'
require 'webrick/httpproxy'

$: << '.'
$: << './bin'
require 'advtwit'

module AdvTwit

class AdvTwitServlet < WEBrick::HTTPServlet::AbstractServlet
  SERVLETROOT = 'atw'

  def initialize(server, core)
    @core = core
  end

  def do_GET(req, res)
    if req.path =~ /^\/#{SERVLETROOT}\/statuses\/advtwit_timeline.(\w+)/
      do_timeline(req, res, $1)
    else
      res.body = req.path
    end

    res['content-type'] = 'text/plain'
  end

  def do_timeline(req, res, format)
    case format
    when 'xml'
      res.body = 'todo'
      res['content-type'] = 'text/plain'
    when 'json'
      res.body = @core.timeline.to_json
      res['content-type'] = 'text/javascript+json; charset=utf-8'
    else
      res.body = @core.timeline.to_s
      res['content-type'] = 'text/plain'
    end
  end

end

class ProxyServer < WEBrick::HTTPProxyServer

  def initialize(settings, core)
    super settings

    mount('/' + AdvTwitServlet::SERVLETROOT, AdvTwitServlet, core)
  end

  def proxy_service(req, res)
    if toward_twitter?(req.request_uri)
      # do_service(req, res) 
      req.request_uri.host = "localhost"
      req.request_uri.port = @config[:Port]
    end

    super(req, res)
  end

  def toward_myself?(uri)
    uri.scheme == "http" and
    uri.host == "localhost" and # fix here
    uri.port == @config[:Port]
  end

  def toward_twitter?(uri)
    uri.scheme == "http" and
    uri.host == "twitter.com" and
    uri.port == 80
  end

  def do_service(req, res)
    res.body = "gotcha!"
    res['Content-Type'] = 'text/plain'
  end
end

end # of module AdvTwit

if __FILE__ == $0
  core = AdvTwit::App.new($advtwit_opts)

  Thread.start {
    loop do
      core.update_twit
      puts "loaded latest tweets! :-)"
      sleep 180
    end
  }

  s = AdvTwit::ProxyServer.new({
    :DocumentRoot => 'var/www',
    :Port => 8000
    }, core)

  Signal.trap('INT') do
    s.shutdown
  end

  s.start
end
