/*
Copyright 2022 Frizlab

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

import Foundation

import StreamReader



extension StreamReader {
	
	func readVarint() throws -> Int {
		var res = 0
		var curByte: UInt8
		var curBitNumber = 0
		
		repeat {
			curByte = try readType()
			var curByteAsInt = Int(0)
			withUnsafeMutableBytes(of: &curByteAsInt, { bytes in
				bytes.baseAddress!.storeBytes(of: curByte, as: UInt8.self)
			})
			res |= (curByteAsInt & 0b0111_1111) << curBitNumber
			curBitNumber += 7
		} while (curByte & 0b1000_0000) == 0
		
		guard curBitNumber <= MemoryLayout<Int>.size * 8 else {
			throw Err.foundTooBigVarint
		}
		
		return res
	}
	
}
