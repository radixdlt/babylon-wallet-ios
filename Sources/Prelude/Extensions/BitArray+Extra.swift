import BitCollections

public extension BitArray {
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

public extension BitArray {
	init(indices: [UInt11]) {
		self.init(indices)
	}

	init?(binaryString: String) {
		var boolArray = [Bool](repeating: false, count: binaryString.count)
		for (index, bit) in binaryString.enumerated() {
			switch bit {
			case "0": continue
			case "1": boolArray[index] = true
			default: return nil
			}
		}

		self.init(boolArray)
	}

	/// A non-optimized initializer taking an array of `UInt11`
	init<S>(_ elements: S) where S: Sequence, S.Iterator.Element == UInt11 {
		let binaryString: String = elements.map(\.binaryString).joined()

		guard
			let bitArray = BitArray(binaryString: binaryString)
		else {
			fatalError("Should always be able to create BitArray from [UInt11] binaryString: '\(binaryString)'")
		}

		self = bitArray
	}
}
