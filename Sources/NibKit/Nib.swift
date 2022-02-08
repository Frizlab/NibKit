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



public struct Nib {
	
	public static let maxVersionMajorSupported: Int32 = 1
	public static let maxVersionMinorSupported: Int32 = 10 /* Technically 9 as reverse engineer comes from version 1.9… */
	
	/** The nib header: "NIBArchive". */
	public static let header = Data([0x4E, 0x49, 0x42, 0x41, 0x72, 0x63, 0x68, 0x69, 0x76, 0x65])
	
	public var versionMajor: Int32
	public var versionMinor: Int32
	
	public var objects: [Object]
	public var keys: [String]
	public var entries: [Entry]
	public var classNames: [String]
	
	public init(url: URL) throws {
		let fh = try FileHandle(forReadingFrom: url)
		try self.init(streamReader: FileHandleReader(stream: fh, bufferSize: 512, bufferSizeIncrement: 128, readSizeLimit: nil, underlyingStreamReadSizeLimit: nil))
	}
	
	/**
	 Parse a nib from a stream.
	 
	 - Parameter streamReader: The stream to read from.
	 - Parameter checkVersionCompatibility: If `true` and version of nib in stream is greater than supported version, we throw an error. If `false` version in nib is ignored. */
	public init(streamReader: StreamReader, checkVersionCompatibility: Bool = true) throws {
		/* Parse nib header. */
		let header = try streamReader.readData(size: Self.header.count)
		guard header == Self.header else {
			throw Err.invalidHeader
		}
		
		/* Parse nib version. */
		let versionMajorLE: Int32 = try streamReader.readType()
		let versionMinorLE: Int32 = try streamReader.readType()
		versionMajor = Int32(littleEndian: versionMajorLE)
		versionMinor = Int32(littleEndian: versionMinorLE)
		guard (
			!checkVersionCompatibility ||
			versionMajor < Self.maxVersionMajorSupported ||
			(versionMajor == Self.maxVersionMajorSupported && versionMinor <= Self.maxVersionMinorSupported)
		) else {
			throw Err.unsupportedVersion
		}
		
		let objectsCountLE:      Int32 = try streamReader.readType()
		let objectsDataOffsetLE: Int32 = try streamReader.readType()
		let objectsCount      = Int32(littleEndian: objectsCountLE)
		let objectsDataOffset = Int32(littleEndian: objectsDataOffsetLE)
		
		let keysCountLE:      Int32 = try streamReader.readType()
		let keysDataOffsetLE: Int32 = try streamReader.readType()
		let keysCount      = Int32(littleEndian: keysCountLE)
		let keysDataOffset = Int32(littleEndian: keysDataOffsetLE)
		
		let entriesCountLE:      Int32 = try streamReader.readType()
		let entriesDataOffsetLE: Int32 = try streamReader.readType()
		let entriesCount      = Int32(littleEndian: entriesCountLE)
		let entriesDataOffset = Int32(littleEndian: entriesDataOffsetLE)
		
		let classNamesCountLE:      Int32 = try streamReader.readType()
		let classNamesDataOffsetLE: Int32 = try streamReader.readType()
		let classNamesCount      = Int32(littleEndian: classNamesCountLE)
		let classNamesDataOffset = Int32(littleEndian: classNamesDataOffsetLE)
		
		throw Err.unsupportedVersion
	}
	
	/**
	 Memberwise initializer.
	 
	 Usually you’ll want to use the stream initializer and its variants (file based). */
	public init(versionMajor: Int32, versionMinor: Int32, objects: [Nib.Object], keys: [String], entries: [Nib.Entry], classNames: [String]) {
		self.versionMajor = versionMajor
		self.versionMinor = versionMinor
		self.objects = objects
		self.keys = keys
		self.entries = entries
		self.classNames = classNames
	}
	
	public struct Object {
		
		public var className: String
		public var valuesStartIndex: Int
		public var valuesCount: Int
		
		public init(className: String, valuesStartIndex: Int, valuesCount: Int) {
			self.className = className
			self.valuesStartIndex = valuesStartIndex
			self.valuesCount = valuesCount
		}
		
	}
	
	public struct Entry {
		
		public var keyIndex: Int
		public var value: Value
		
		public init(keyIndex: Int, value: Nib.Entry.Value) {
			self.keyIndex = keyIndex
			self.value = value
		}
		
		public enum Value {
			
			case int8(Int8)
			case int16(Int16)
			case int32(Int32)
			case int64(Int64)
			case `true`
			case `false`
			case float(Float32)
			case double(Float64)
			case data(Data)
			case `nil`
			case object(atIndex: Int)
			
		}
		
	}
	
	public struct ClassName {
		
		public var extraValues: [Int32]
		public var className: String
		
		public init(extraValues: [Int32], className: String) {
			self.extraValues = extraValues
			self.className = className
		}
		
	}
	
}
