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

require_relative 'framer'

require 'http/hpack/context'
require 'http/hpack/compressor'
require 'http/hpack/decompressor'

module HTTP
	module Protocol
		module HTTP2
			class Connection
				def initialize(framer, next_stream_id, local_settings = Settings.new)
					@state = :new
					@streams = {}
					
					@framer = framer
					@next_stream_id = next_stream_id
					
					@local_settings = local_settings
					@remote_settings = Settings.new
					
					@decoder = HPACK::Context.new
					@encoder = HPACK::Context.new
					
					@pending_settings = nil
					
					@local_window_limit = @local_settings.initial_window_size
					@local_window = @local_window_limit
					
					@remote_window_limit = @remote_settings.initial_window_size
					@remote_window = @remote_window_limit
				end
				
				# Connection state (:new, :closed).
				attr :state

				# Size of current connection flow control window (by default, set to
				# infinity, but is automatically updated on receipt of peer settings).
				attr :local_window
				attr :remote_window
				alias window local_window

				# Current settings value for local and peer
				attr :local_settings
				attr :remote_settings

				# Pending settings value
				#  Sent but not ack'ed settings
				attr :pending_settings

				# Number of active streams between client and server (reserved streams
				# are not counted towards the stream limit).
				attr :active_stream_count
				
				def closed?
					@state == :closed
				end
				
				def encode_headers(headers, buffer = String.new.b)
					HPACK::Compressor.new(buffer, @encoder).encode(headers)
					
					return buffer
				end
				
				def decode_headers(data)
					HPACK::Decompressor.new(data, @decoder).decode
				end
				
				# Streams are identified with an unsigned 31-bit integer.  Streams initiated by a client MUST use odd-numbered stream identifiers; those initiated by the server MUST use even-numbered stream identifiers.  A stream identifier of zero (0x0) is used for connection control messages; the stream identifier of zero cannot be used to establish a new stream.
				def next_stream_id
					id = @next_stream_id
					
					@next_stream_id += 2
					
					return id
				end
				
				attr :streams
				
				def read_frame
					frame = @framer.read_frame
					
					frame.apply(self)
					
					return frame
				end
				
				def send_ping(data)
					if @state != :closed
						frame = PingFrame.new
						frame.pack data
						
						@framer.write_frame(frame)
					else
						raise ProtocolError, "Cannot send ping in state #{@state}"
					end
				end
				
				def receive_ping(frame)
					if @state != :closed
						unless frame.acknowledgement?
							reply = frame.acknowledge
							
							@framer.write_frame(frame)
						end
					else
						raise ProtocolError, "Cannot receive ping in state #{@state}"
					end
				end
				
				def receive_data(frame)
					if stream = @streams[frame.stream_id]
						stream.receive_data(frame)
						
						if stream.closed?
							@streams.delete(stream.id)
						end
					else
						raise ProtocolError, "Bad stream"
					end
				end
				
				def receive_headers(frame)
					if stream = @streams[frame.stream_id]
						stream.receive_headers(frame)
						
						if stream.closed?
							@streams.delete(stream.id)
						end
					else
						raise ProtocolError, "Bad stream"
					end
				end
				
				def receive_priority(frame)
					if stream = @streams[frame.stream_id]
						stream.receive_priority(frame)
					else
						raise ProtocolError, "Bad stream"
					end
				end
				
				def receive_reset_stream(frame)
					if stream = @streams[frame.stream_id]
						stream.receive_reset_stream(frame)
						
						@streams.delete(stream.id)
					else
						raise ProtocolError, "Bad stream"
					end
				end
			end
		end
	end
end