import Foundation

extension BitArray {
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
