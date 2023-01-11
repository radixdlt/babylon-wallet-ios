public extension BitArray {
	static func |= (left: inout Self, right: Self) {
		precondition(left.count == right.count)
		left._update { target in
			right._read { source in
				for i in 0 ..< target._words.count {
					target._mutableWords[i].formUnion(source._words[i])
				}
			}
		}
		left._checkInvariants()
	}

	static func | (left: Self, right: Self) -> Self {
		precondition(left.count == right.count)
		var result = left
		result |= right
		return result
	}

	static func &= (left: inout Self, right: Self) {
		precondition(left.count == right.count)
		left._update { target in
			right._read { source in
				for i in 0 ..< target._words.count {
					target._mutableWords[i].formIntersection(source._words[i])
				}
			}
		}
		left._checkInvariants()
	}

	static func & (left: Self, right: Self) -> Self {
		precondition(left.count == right.count)
		var result = left
		result &= right
		return result
	}

	static func ^= (left: inout Self, right: Self) {
		precondition(left.count == right.count)
		left._update { target in
			right._read { source in
				for i in 0 ..< target._words.count {
					target._mutableWords[i].formSymmetricDifference(source._words[i])
				}
			}
		}
		left._checkInvariants()
	}

	static func ^ (left: Self, right: Self) -> Self {
		precondition(left.count == right.count)
		var result = left
		result ^= right
		return result
	}

	static prefix func ~ (value: Self) -> Self {
		var result = value
		result._update { handle in
			for i in 0 ..< handle._words.count {
				handle._mutableWords[i].formComplement()
			}
			let p = _BitPosition(handle._count)
			if p.bit > 0 {
				handle._mutableWords[p.word].subtract(_Word(upTo: p.bit).complement())
			}
		}
		result._checkInvariants()
		return result
	}
}
