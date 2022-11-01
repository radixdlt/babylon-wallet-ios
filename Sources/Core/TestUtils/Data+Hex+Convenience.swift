import Common
import Foundation
import Mnemonic

public extension String {
	var hexData: Data {
		try! Data(hex: self)
	}
}
