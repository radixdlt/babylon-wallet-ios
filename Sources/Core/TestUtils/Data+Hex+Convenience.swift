import Prelude

public extension String {
	var hexData: Data {
		try! Data(hex: self)
	}
}
