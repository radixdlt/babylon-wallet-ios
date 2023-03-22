import CryptoKit
import EngineToolkit
import Foundation
import RadixConnectModels

extension Data {
	var hash: Data {
		try! blake2b(data: self)
	}
}

extension ConnectionPassword {
	var hash: Data {
		self.data.data.hash
	}
}
