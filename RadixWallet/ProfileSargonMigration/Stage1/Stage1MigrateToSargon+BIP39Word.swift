import Foundation
import Sargon

public typealias BIP39Word = Bip39Word

// MARK: Identifiable
extension BIP39Word: Identifiable {
	public typealias ID = U11
	public var id: ID {
		self.index
	}
}
