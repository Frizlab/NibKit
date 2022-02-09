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



extension OutputStream {
	
	func write(dataPtr: UnsafeRawBufferPointer) throws -> Int {
		var countToWrite = dataPtr.count
		guard countToWrite > 0 else {return 0}
		
		var memToWrite = dataPtr.bindMemory(to: UInt8.self).baseAddress! /* !-safe because we have checked against a 0-length buffer. */
		while countToWrite > 0 {
			/* Note: This blocks until at least 1 byte is written to the stream (or an error occurs). */
			let writeRes = write(memToWrite, maxLength: countToWrite)
			guard writeRes > 0 else {throw Err.cannotWriteToStream(streamError: streamError)}
			
			memToWrite = memToWrite.advanced(by: writeRes)
			countToWrite -= writeRes
		}
		
		return dataPtr.count
	}
	
	func write(data: Data) throws -> Int {
		try data.withUnsafeBytes{ try write(dataPtr: $0) }
	}
	
	func write<T>(value: inout T) throws -> Int {
		let size = MemoryLayout<T>.size
		guard size > 0 else {return 0} /* Void size is 0 */
		
		return try withUnsafePointer(to: &value, { pointer -> Int in
			return try write(dataPtr: UnsafeRawBufferPointer(UnsafeBufferPointer<T>(start: pointer, count: 1)))
		})
	}
	
	func write(intAsLittleEndian value: Int32) throws -> Int {
		var value = value.littleEndian
		return try write(value: &value)
	}
	
	func write(varint: Int) throws -> Int {
		var res = 0
		var currentValue = varint
		repeat {
			var toWrite = withUnsafeBytes(of: currentValue, { bytes in bytes.first! & 0b0111_1111 })
			
			currentValue >>= 7
			if currentValue == 0 {toWrite |= 0b1000_0000}
			
			res += try write(value: &toWrite)
		} while currentValue != 0
		return res
	}
	
}
