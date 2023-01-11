import Foundation

extension BitArray {
	// https://stackoverflow.com/a/28930093/1311272
	func asBytesArray() -> [UInt8] {
		let numBits = self.count
		let numBytes = (numBits + 7) / 8
		var bytes = [UInt8](repeating: 0, count: numBytes)

		for (index, bit) in self.enumerated() where bit == true {
			bytes[index / 8] += UInt8(1 << (7 - index % 8))
		}

		return bytes
	}

	func asData() -> Data {
		Data(self.asBytesArray())
	}

	init(data: Data) {
		self.init(binaryString: data.binaryString)!
	}

	var binaryString: String { map { "\($0 == true ? 1 : 0)" }.joined() }
}
