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

@testable import NibKit



final class NibKitTests : XCTestCase {
	
	func testNib1() throws {
		let nib1Data = try Data(contentsOf: testsDataURL.appendingPathComponent("nib1.nib"))
		
		let nib1 = try Nib(data: nib1Data)
		XCTAssertEqual(nib1.versionMajor, 1)
		XCTAssertEqual(nib1.versionMinor, 10)
		try XCTAssertEqual(nib1Data, nib1.serialized())
	}
	
	private let testsDataURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("TestsData")
	
}
