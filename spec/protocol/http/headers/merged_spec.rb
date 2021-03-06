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

require 'protocol/http/headers'

RSpec.describe Protocol::HTTP::Headers::Merged do	
	let(:fields) do
		[
			['Content-Type', 'text/html'],
			['Set-Cookie', 'hello=world'],
			['Accept', '*/*'],
			['content-length', 10],
		]
	end
	
	subject{described_class.new(fields)}
	let(:headers) {Protocol::HTTP::Headers.new(subject)}
	
	describe '#each' do
		it 'should yield keys as lower case' do
			subject.each do |key, value|
				expect(key).to be == key.downcase
			end
		end
		
		it 'should yield values as strings' do
			subject.each do |key, value|
				expect(value).to be_kind_of String
			end
		end
	end
	
	describe '#<<' do
		it "can append fields" do
			subject << [["Accept", "image/jpeg"]]
			
			expect(headers['accept']).to be == ['*/*', 'image/jpeg']
		end
	end
end
