import Foundation
import Sargon

public typealias BIP39WordCount = Bip39WordCount

extension BIP39WordCount {
	public init?(wordCount: Int) {
		self.init(rawValue: UInt8(wordCount))
	}
}
