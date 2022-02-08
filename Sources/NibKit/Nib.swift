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



public struct Nib {
	
	public var objects: [Object]
	public var keys: [String]
	public var entries: [Entry]
	public var classNames: [String]
	
	public struct Object {
		
		public var className: String
		public var valuesStartIndex: Int
		public var valuesCount: Int
		
	}
	
	public struct Entry {
		
		public var keyIndex: Int
		public var value: Value
		
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
		
	}
	
}
