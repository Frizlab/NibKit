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
import XCTest

import StreamReader

@testable import NibKit



final class VarintTests : XCTestCase {
	
	func testVarint1Byte() throws {
		try XCTAssertEqual(DataReader(data: Data([0b1000_0000])).readVarint(), 0b0000_0000)
		try XCTAssertEqual(DataReader(data: Data([0b1010_1010])).readVarint(), 0b0010_1010)
		try XCTAssertEqual(DataReader(data: Data([0b1111_1111])).readVarint(), 0b0111_1111)
		
		try XCTAssertEqual(data(from: 0),   Data([0b1000_0000]))
		try XCTAssertEqual(data(from: 127), Data([0b1111_1111]))
	}
	
	func testVarint2Bytes() throws {
		try XCTAssertEqual(DataReader(data: Data([0b0000_0000, 0b1000_0000])).readVarint(), 0b0000_0000_0000_0000)
		try XCTAssertEqual(DataReader(data: Data([0b0100_0000, 0b1000_0000])).readVarint(), 0b0000_0000_0100_0000)
		try XCTAssertEqual(DataReader(data: Data([0b0000_0000, 0b1100_0000])).readVarint(), 0b0010_0000_0000_0000)
	}
	
	/* Technically we’re in uncharted territory here! */
	func testVarint3Bytes() throws {
		try XCTAssertEqual(DataReader(data: Data([0b0000_0000, 0b0000_0000, 0b1000_0000])).readVarint(), 0b0000_0000_0000_0000_0000_0000)
		try XCTAssertEqual(DataReader(data: Data([0b0100_0000, 0b0000_0000, 0b1000_0000])).readVarint(), 0b0000_0000_0000_0000_0100_0000)
		try XCTAssertEqual(DataReader(data: Data([0b0000_0000, 0b0100_0000, 0b1100_0000])).readVarint(), 0b0001_0000_0010_0000_0000_0000)
		try XCTAssertEqual(DataReader(data: Data([0b0000_0000, 0b0100_0000, 0b1000_0000])).readVarint(), 0b0000_0000_0010_0000_0000_0000)
		try XCTAssertEqual(DataReader(data: Data([0b0000_0000, 0b0000_0000, 0b1100_0000])).readVarint(), 0b0001_0000_0000_0000_0000_0000)
	}
	
	private func data(from varint: Int) throws -> Data {
		let stream = OutputStream(toMemory: ())
		stream.open(); defer {stream.close()}
		
		_ = try stream.write(varint: varint)
		
		/* Note: Are we really allowed to access dataWrittenToMemoryStreamKey while the stream is not closed? */
		guard let nsdata = stream.property(forKey: Stream.PropertyKey.dataWrittenToMemoryStreamKey) as? NSData else {
			throw Err.internalError
		}
		
		return Data(referencing: nsdata)
	}
	
}
