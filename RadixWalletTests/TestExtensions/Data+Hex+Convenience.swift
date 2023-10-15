import Foundation

extension String {
	public var hexData: Data {
		try! Data(hex: self)
	}
}
