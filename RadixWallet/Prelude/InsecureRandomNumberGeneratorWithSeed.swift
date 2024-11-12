// MARK: - InsecureRandomNumberGeneratorWithSeed
struct InsecureRandomNumberGeneratorWithSeed: RandomNumberGenerator {
	init(seed: Int) {
		// Set the random seed
		srand48(seed)
	}
}

extension InsecureRandomNumberGeneratorWithSeed {
	init(data: Data) {
		let intByteCount = (Int.bitWidth / Int.bitsPerByte)
		precondition(data.count >= intByteCount)
		let bytes = [UInt8](data.suffix(intByteCount))
		let seedInt = bytes.withUnsafeBytes {
			$0.load(as: Int.self)
		}
		self.init(seed: seedInt < 0 ? seedInt.negated() : seedInt)
	}
}

extension SignedInteger {
	func negated() -> Self {
		var copy = self
		copy.negate()
		return copy
	}
}

extension InsecureRandomNumberGeneratorWithSeed {
	func next() -> UInt64 {
		// drand48() returns a Double, transform to UInt64
		withUnsafeBytes(of: drand48()) { bytes in
			bytes.load(as: UInt64.self)
		}
	}
}
