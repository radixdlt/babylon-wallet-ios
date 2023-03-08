import Foundation
import RadixConnectModels

import CryptoKit

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
