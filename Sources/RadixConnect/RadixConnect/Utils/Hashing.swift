import CryptoKit
import Foundation
import RadixConnectModels

extension Data {
	var hash: Data {
		Data(SHA256.hash(data: self))
	}
}

extension ConnectionPassword {
	var hash: Data {
		self.data.data.hash
	}
}
