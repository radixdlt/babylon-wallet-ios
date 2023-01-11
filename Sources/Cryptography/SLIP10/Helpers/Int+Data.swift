import Foundation

extension FixedWidthInteger {
	var data: Data {
		let data = withUnsafeBytes(of: self.bigEndian) { Data($0) }
		return data
	}
}
