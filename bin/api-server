#!/usr/bin/env python3

import os
import sys
import ssl
import json

from wsgiref.simple_server import make_server

def app(environ, start_response):

  status  = '200 OK'
  headers = [
    ('Content-type', 'Application/json; charset=utf-8'),
    ('Access-Control-Allow-Origin', '*'),
  ]
  start_response(status, headers)

  # TODO: importlib.SourceFileLoaderで動的に実行

  return [json.dumps({'status':'success'}).encode("utf-8")]

def run(host, port, ctx, app):

  server = make_server(host, port, app)
  server.socket = ctx.wrap_socket(server.socket)

  print('listen - %s:%s' % (host, port))

  try:
    server.serve_forever()
  except KeyboardInterrupt:
    pass

  server.server_close()

if __name__ == '__main__':

  domain = 'api.tkyz.jp'

  host = 'localhost'
  port = 443
  crt  = os.environ['HOME'] + '/.secrets/pki/certs/' + domain + '/crt'
  key  = os.environ['HOME'] + '/.secrets/pki/certs/' + domain + '/key'

  if os.path.exists('/.dockerenv'):
    host = domain
    port = 443
    crt  = '/tls.crt'
    key  = '/tls.key'

  ctx = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
  ctx.load_cert_chain(crt, key)
  ctx.options |= ssl.OP_NO_TLSv1
  ctx.options |= ssl.OP_NO_TLSv1_1

  run(host, port, ctx, app)
