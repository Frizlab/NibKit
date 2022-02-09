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
	public var classNames: [ClassName]
	
	public init(url: URL) throws {
		let fh = try FileHandle(forReadingFrom: url)
		try self.init(streamReader: FileHandleReader(stream: fh, bufferSize: 512, bufferSizeIncrement: 128, readSizeLimit: nil, underlyingStreamReadSizeLimit: nil))
	}
	
	public init(data: Data) throws {
		try self.init(streamReader: DataReader(data: data))
	}
	
	/**
	 Parse a nib from a stream.
	 
	 - Parameter streamReader: The stream to read from.
	 - Parameter checkVersionCompatibility: If `true` and version of nib in stream is greater than supported version, we throw an error. If `false` version in nib is ignored. */
	public init(streamReader: StreamReader, checkVersionCompatibility: Bool = true) throws {
		let initialReadPosition = streamReader.currentReadPosition
		
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
		
		func readStreamInitableObjects<ObjectType : StreamInitable>(expectedOffset: Int32, objectsCount: Int32) throws -> [ObjectType] {
			let relativeReadPosition = streamReader.currentReadPosition - initialReadPosition
			guard Int32(relativeReadPosition) == expectedOffset else {
				throw Err.foundUnknownData(offset: relativeReadPosition)
			}
			return try (0..<objectsCount).map{ _ in try ObjectType(streamReader: streamReader) }
		}
		
		var objects: [Object]!
		let objectsCountLE:      Int32 = try streamReader.readType()
		let objectsDataOffsetLE: Int32 = try streamReader.readType()
		let objectsCount      = Int32(littleEndian: objectsCountLE)
		let objectsDataOffset = Int32(littleEndian: objectsDataOffsetLE)
		let objectsSetter = { objects = try readStreamInitableObjects(expectedOffset: objectsDataOffset, objectsCount: objectsCount) }
		
		var keys: [String]!
		let keysCountLE:      Int32 = try streamReader.readType()
		let keysDataOffsetLE: Int32 = try streamReader.readType()
		let keysCount      = Int32(littleEndian: keysCountLE)
		let keysDataOffset = Int32(littleEndian: keysDataOffsetLE)
		let keysSetter = { keys = try readStreamInitableObjects(expectedOffset: keysDataOffset, objectsCount: keysCount) }
		
		var entries: [Entry]!
		let entriesCountLE:      Int32 = try streamReader.readType()
		let entriesDataOffsetLE: Int32 = try streamReader.readType()
		let entriesCount      = Int32(littleEndian: entriesCountLE)
		let entriesDataOffset = Int32(littleEndian: entriesDataOffsetLE)
		let entriesSetter = { entries = try readStreamInitableObjects(expectedOffset: entriesDataOffset, objectsCount: entriesCount) }
		
		var classNames: [ClassName]!
		let classNamesCountLE:      Int32 = try streamReader.readType()
		let classNamesDataOffsetLE: Int32 = try streamReader.readType()
		let classNamesCount      = Int32(littleEndian: classNamesCountLE)
		let classNamesDataOffset = Int32(littleEndian: classNamesDataOffsetLE)
		let classNamesSetter = { classNames = try readStreamInitableObjects(expectedOffset: classNamesDataOffset, objectsCount: classNamesCount) }
		
		let settersAndOffset = [
			(   objectsDataOffset,    objectsSetter),
			(      keysDataOffset,       keysSetter),
			(   entriesDataOffset,    entriesSetter),
			(classNamesDataOffset, classNamesSetter)
		]
		
		try settersAndOffset.sorted{ $0.0 < $1.0 }.forEach{ try $0.1() }
		
		self.objects = objects
		self.keys = keys
		self.entries = entries
		self.classNames = classNames
	}
	
	/**
	 Memberwise initializer.
	 
	 Usually you’ll want to use the stream initializer and its variants (file based). */
	public init(versionMajor: Int32, versionMinor: Int32, objects: [Nib.Object], keys: [String], entries: [Nib.Entry], classNames: [ClassName]) {
		self.versionMajor = versionMajor
		self.versionMinor = versionMinor
		self.objects = objects
		self.keys = keys
		self.entries = entries
		self.classNames = classNames
	}
	
	public func serialized(skipSkizes: Bool = false) throws -> Data {
		let stream = OutputStream(toMemory: ())
		
		stream.open()
		defer {stream.close()}
		
		var written = 0
		written += try stream.write(data: Self.header)
		written += try stream.write(intAsLittleEndian: versionMajor)
		written += try stream.write(intAsLittleEndian: versionMinor)
		
		written += try stream.write(intAsLittleEndian: Int32(objects.count))
		let objectsOffsetOffset = written
		written += try stream.write(intAsLittleEndian: Int32(0)) /* Start offset. */
		
		written += try stream.write(intAsLittleEndian: Int32(keys.count))
		let keysOffsetOffset = written
		written += try stream.write(intAsLittleEndian: Int32(0)) /* Start offset. */
		
		written += try stream.write(intAsLittleEndian: Int32(entries.count))
		let entriesOffsetOffset = written
		written += try stream.write(intAsLittleEndian: Int32(0)) /* Start offset. */
		
		written += try stream.write(intAsLittleEndian: Int32(classNames.count))
		let classNamesOffsetOffset = written
		written += try stream.write(intAsLittleEndian: Int32(0)) /* Start offset. */
		
		let objectsOffset = written
		written += try objects.reduce(0, { try $0 + $1.write(to: stream) })
		
		let keysOffset = written
		written += try keys.reduce(0, { try $0 + $1.write(to: stream) })
		
		let entriesOffset = written
		written += try entries.reduce(0, { try $0 + $1.write(to: stream) })
		
		let classNamesOffset = written
		written += try classNames.reduce(0, { try $0 + $1.write(to: stream) })
		
		/* Note: Are we really allowed to access dataWrittenToMemoryStreamKey while the stream is not closed? */
		guard let nsdata = stream.property(forKey: Stream.PropertyKey.dataWrittenToMemoryStreamKey) as? NSData else {
			throw Err.internalError
		}
		
		var data = Data(referencing: nsdata)
		if !skipSkizes {
			data.withUnsafeMutableBytes{ (bytes: UnsafeMutableRawBufferPointer) -> Void in
				let baseAddress = bytes.baseAddress!
				(baseAddress +    objectsOffsetOffset).bindMemory(to: Int32.self, capacity: 1).pointee = Int32(objectsOffset)
				(baseAddress +       keysOffsetOffset).bindMemory(to: Int32.self, capacity: 1).pointee = Int32(keysOffset)
				(baseAddress +    entriesOffsetOffset).bindMemory(to: Int32.self, capacity: 1).pointee = Int32(entriesOffset)
				(baseAddress + classNamesOffsetOffset).bindMemory(to: Int32.self, capacity: 1).pointee = Int32(classNamesOffset)
			}
		}
		
		return data
	}
	
	public struct Object : StreamInitable {
		
		public var classNameIndex: Int
		public var valuesStartIndex: Int
		public var valuesCount: Int
		
		public init(classNameIndex: Int, valuesStartIndex: Int, valuesCount: Int) {
			self.classNameIndex = classNameIndex
			self.valuesStartIndex = valuesStartIndex
			self.valuesCount = valuesCount
		}
		
		init(streamReader: StreamReader) throws {
			self.classNameIndex   = try streamReader.readVarint()
			self.valuesStartIndex = try streamReader.readVarint()
			self.valuesCount      = try streamReader.readVarint()
		}
		
		func write(to stream: OutputStream) throws -> Int {
			var res = 0
			res += try stream.write(varint: classNameIndex)
			res += try stream.write(varint: valuesStartIndex)
			res += try stream.write(varint: valuesCount)
			return res
		}
		
	}
	
	public struct Entry : StreamInitable {
		
		public var keyIndex: Int
		public var value: Value
		
		public init(keyIndex: Int, value: Nib.Entry.Value) {
			self.keyIndex = keyIndex
			self.value = value
		}
		
		init(streamReader: StreamReader) throws {
			self.keyIndex = try streamReader.readVarint()
			let valueType: UInt8 = try streamReader.readType()
			switch valueType {
				case 0:
					self.value = try .int8(streamReader.readType())
					
				case 1:
					let valueLE: Int16 = try streamReader.readType()
					self.value = .int16(Int16(littleEndian: valueLE))
					
				case 2:
					let valueLE: Int32 = try streamReader.readType()
					self.value = .int32(Int32(littleEndian: valueLE))
					
				case 3:
					let valueLE: Int64 = try streamReader.readType()
					self.value = .int64(Int64(littleEndian: valueLE))
					
				case 4:
					self.value = .true
					
				case 5:
					self.value = .false
					
				case 6:
					self.value = try .float(streamReader.readType())
					
				case 7:
					self.value = try .double(streamReader.readType())
					
				case 8:
					let dataSize = try streamReader.readVarint()
					self.value = try .data(streamReader.readData(size: dataSize))
					
				case 9:
					self.value = .nil
					
				case 10:
					let offsetLE: Int32 = try streamReader.readType()
					let offset = Int32(littleEndian: offsetLE)
					self.value = .object(atIndex: Int(offset))
					
				default:
					throw Err.foundUnknownValueType(valueType)
			}
		}
		
		func write(to stream: OutputStream) throws -> Int {
			var res = 0
			res += try stream.write(varint: keyIndex)
			switch value {
				case .int8(var int8):
					var valueType: UInt8 = 0
					res += try stream.write(value: &valueType)
					res += try stream.write(value: &int8)
					
				case .int16(let int16):
					var valueType: UInt8 = 1
					var int16LE = int16.littleEndian
					res += try stream.write(value: &valueType)
					res += try stream.write(value: &int16LE)
					
				case .int32(let int32):
					var valueType: UInt8 = 2
					var int32LE = int32.littleEndian
					res += try stream.write(value: &valueType)
					res += try stream.write(value: &int32LE)
					
				case .int64(let int64):
					var valueType: UInt8 = 3
					var int64LE = int64.littleEndian
					res += try stream.write(value: &valueType)
					res += try stream.write(value: &int64LE)
					
				case .true:
					var valueType: UInt8 = 4
					res += try stream.write(value: &valueType)
					
				case .false:
					var valueType: UInt8 = 5
					res += try stream.write(value: &valueType)
					
				case .float(var float32):
					var valueType: UInt8 = 6
					res += try stream.write(value: &valueType)
					res += try stream.write(value: &float32)
					
				case .double(var float64):
					var valueType: UInt8 = 7
					res += try stream.write(value: &valueType)
					res += try stream.write(value: &float64)
					
				case .data(let data):
					var valueType: UInt8 = 8
					res += try stream.write(value: &valueType)
					res += try stream.write(varint: data.count)
					res += try stream.write(data: data)
					
				case .nil:
					var valueType: UInt8 = 9
					res += try stream.write(value: &valueType)
					
				case .object(let index):
					var valueType: UInt8 = 10
					var indexLE = index.littleEndian
					res += try stream.write(value: &valueType)
					res += try stream.write(value: &indexLE)
			}
			return res
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
	
	public struct ClassName : StreamInitable {
		
		public var extraValues: [Int32]
		public var className: String
		
		public init(extraValues: [Int32], className: String) {
			self.extraValues = extraValues
			self.className = className
		}
		
		init(streamReader: StreamReader) throws {
			let classNameLength  = try streamReader.readVarint()
			let extraValuesCount = try streamReader.readVarint()
			self.extraValues = try (0..<extraValuesCount).map{ _ in
				let valLE: Int32 = try streamReader.readType()
				return Int32(littleEndian: valLE)
			}
			let classNameData = try streamReader.readData(size: classNameLength)
			guard classNameData.last == 0 else {
				throw Err.foundUnterminatedString(data: classNameData)
			}
			self.className = classNameData.withUnsafeBytes{ rawBufferPointer in
				/* baseAddress is bang-safe because we are certain the classNameData contains at least one element (the final 0). */
				String(cString: rawBufferPointer.baseAddress!.assumingMemoryBound(to: UInt8.self))
			}
		}
		
		func write(to stream: OutputStream) throws -> Int {
			guard let cString = className.cString(using: .utf8) else {
				throw Err.internalError
			}
			
			var res = 0
			res += try stream.write(varint: cString.count)
			res += try stream.write(varint: extraValues.count)
			res += try extraValues.reduce(0, { try $0 + stream.write(intAsLittleEndian: $1) })
			res += try cString.withUnsafeBytes{ try stream.write(dataPtr: $0) }
			return res
		}
		
	}
	
}


private protocol StreamInitable {
	
	init(streamReader: StreamReader) throws
	
}


extension String : StreamInitable {
	
	/* Specifically this is the “Key” format.
	 * Some other strings are encoded differently. */
	init(streamReader: StreamReader) throws {
		let keyLength = try streamReader.readVarint()
		let keyData = try streamReader.readData(size: keyLength)
		guard let initialized = Self(data: keyData, encoding: .utf8) else {
			throw Err.foundInvalidUtf8String(data: keyData)
		}
		
		self = initialized
	}
	
	func write(to stream: OutputStream) throws -> Int {
		let utf8Data = Data(utf8)
		
		var res = 0
		res += try stream.write(varint: utf8Data.count)
		res += try stream.write(data: utf8Data)
		return res
	}
	
}
