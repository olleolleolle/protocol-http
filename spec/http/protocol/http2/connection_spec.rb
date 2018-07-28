# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'http/protocol/http2/client'
require 'http/protocol/http2/server'

require 'socket'

RSpec.describe HTTP::Protocol::HTTP2::Connection do
	let(:io) {Socket.pair(Socket::PF_UNIX, Socket::SOCK_STREAM)}
	
	subject(:client) {HTTP::Protocol::HTTP2::Client.new(HTTP::Protocol::HTTP2::Framer.new(io.first))}
	let(:server) {HTTP::Protocol::HTTP2::Server.new(HTTP::Protocol::HTTP2::Framer.new(io.last))}
	
	context HTTP::Protocol::HTTP2::PingFrame do
		it "it can send ping and receive pong" do
			expect(server).to receive(:receive_ping).once.and_call_original
			
			client.send_ping("12345678")
			
			server.read_frame
			
			expect(client).to receive(:receive_ping).once.and_call_original
			
			frame = client.read_frame
		end
	end
end