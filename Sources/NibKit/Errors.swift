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



public enum NibKitError : Error {
	
	case invalidHeader
	case unsupportedVersion
	
	/**
	 In general this error should be ignorable.
	 We assume every byte has meaning in a nib though, which means the error cannot be ignored. */
	case foundUnknownData(offset: Int)
	
	case foundUnknownValueType(UInt8)
	
	case foundTooBigVarint
	case foundInvalidUtf8String(data: Data)
	case foundUnterminatedString(data: Data)
	
	/** An error occurred writing to the stream. */
	case cannotWriteToStream(streamError: Error?)
	
	case internalError
	
}

typealias Err = NibKitError
