import EngineKit
import Foundation
import Prelude
import RadixConnectModels

extension Data {
	func hash() throws -> Data {
		try blake2b(data: self)
	}
}

extension ConnectionPassword {
	func hash() throws -> Data {
		try self.data.data.hash()
	}
}
