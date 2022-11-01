import Bite
import Common
import Foundation

public extension String {
	var hexData: Data {
		try! Data(hex: self)
	}
}
