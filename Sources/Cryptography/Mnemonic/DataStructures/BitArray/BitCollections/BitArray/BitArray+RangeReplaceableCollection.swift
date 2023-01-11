// MARK: - BitArray + RangeReplaceableCollection
extension BitArray: RangeReplaceableCollection {}

public extension BitArray {
	mutating func reserveCapacity(_ n: Int) {
		let wordCount = _Word.wordCount(forBitCount: UInt(n))
		_storage.reserveCapacity(wordCount)
	}

	init() {
		self.init(_storage: [], count: 0)
	}

	init(repeating repeatedValue: Bool, count: Int) {
		let wordCount = _Word.wordCount(forBitCount: UInt(count))
		var storage: [_Word] = .init(
			repeating: repeatedValue ? .allBits : .empty, count: wordCount
		)
		if repeatedValue, _BitPosition(count).bit != 0 {
			// Clear upper bits of last word.
			storage[wordCount - 1] = _Word(upTo: _BitPosition(count).bit)
		}
		self.init(_storage: storage, count: count)
	}
}

public extension BitArray {
	@inlinable
	init<S: Sequence>(_ elements: S) where S.Element == Bool {
		defer { _checkInvariants() }
		if S.self == BitArray.self {
			self = elements as! BitArray
			return
		}
		if S.self == BitArray.SubSequence.self {
			self.init(elements as! BitArray.SubSequence)
			return
		}
		self.init()
		self.reserveCapacity(elements.underestimatedCount)
		self.append(contentsOf: elements)
	}

	// Specializations
	init(_ values: BitArray) {
		self = values
	}

	init(_ values: BitArray.SubSequence) {
		let wordCount = _Word.wordCount(forBitCount: UInt(values.count))
		let storage = Array(repeating: _Word.empty, count: wordCount)
		self.init(_storage: storage, count: values.count)
		self._copy(from: values, to: 0)
		_checkInvariants()
	}
}

public extension BitArray {
	internal mutating func _prepareForReplaceSubrange(
		_ range: Range<Int>, replacementCount c: Int
	) {
		precondition(range.lowerBound >= 0 && range.upperBound <= self.count)

		let origCount = self.count
		if range.count < c {
			_extend(by: c - range.count)
		}

		_copy(from: range.upperBound ..< origCount, to: range.lowerBound + c)

		if c < range.count {
			_removeLast(range.count - c)
		}
	}

	mutating func replaceSubrange<C: Collection>(
		_ range: Range<Int>,
		with newElements: __owned C
	) where C.Element == Bool {
		let c = newElements.count
		_prepareForReplaceSubrange(range, replacementCount: c)
		if C.self == BitArray.self {
			_copy(from: newElements as! BitArray, to: range.lowerBound)
		} else if C.self == BitArray.SubSequence.self {
			_copy(from: newElements as! BitArray.SubSequence, to: range.lowerBound)
		} else {
			_copy(from: newElements, to: range.lowerBound ..< range.lowerBound + c)
		}
		_checkInvariants()
	}

	mutating func replaceSubrange(
		_ range: Range<Int>,
		with newElements: __owned BitArray
	) {
		replaceSubrange(range, with: newElements[...])
	}

	mutating func replaceSubrange(
		_ range: Range<Int>,
		with newElements: __owned BitArray.SubSequence
	) {
		_prepareForReplaceSubrange(range, replacementCount: newElements.count)
		_copy(from: newElements, to: range.lowerBound)
		_checkInvariants()
	}
}

public extension BitArray {
	mutating func append(_ newElement: Bool) {
		let (word, bit) = _BitPosition(_count).split
		if bit == 0 {
			_storage.append(_Word.empty)
		}
		_count += 1
		if newElement {
			_update { handle in
				handle._mutableWords[word].value |= 1 &<< bit
			}
		}
		_checkInvariants()
	}

	mutating func append<S: Sequence>(
		contentsOf newElements: __owned S
	) where S.Element == Bool {
		if S.self == BitArray.self {
			self.append(contentsOf: newElements as! BitArray)
			return
		}
		if S.self == BitArray.SubSequence.self {
			self.append(contentsOf: newElements as! BitArray.SubSequence)
			return
		}
		var it = newElements.makeIterator()
		var pos = _BitPosition(_count)
		if pos.bit > 0 {
			let (bits, count) = it._nextChunk(
				maximumCount: UInt(_Word.capacity) - pos.bit)
			guard count > 0 else { return }
			_count += count
			_update { $0._copy(bits: bits, count: count, to: pos) }
			pos.value += count
		}
		while true {
			let (bits, count) = it._nextChunk()
			guard count > 0 else { break }
			assert(pos.bit == 0)
			_storage.append(.empty)
			_count += count
			_update { $0._copy(bits: bits, count: count, to: pos) }
			pos.value += count
		}
		_checkInvariants()
	}

	mutating func append(contentsOf newElements: BitArray) {
		_extend(by: newElements.count)
		_copy(from: newElements, to: count - newElements.count)
		_checkInvariants()
	}

	mutating func append(contentsOf newElements: BitArray.SubSequence) {
		_extend(by: newElements.count)
		_copy(from: newElements, to: count - newElements.count)
		_checkInvariants()
	}
}

public extension BitArray {
	mutating func insert(_ newElement: Bool, at i: Int) {
		if _BitPosition(_count).bit == 0 {
			_storage.append(_Word.empty)
		}
		let c = count
		_count += 1
		_update { handle in
			handle.copy(from: i ..< c, to: i + 1)
			handle[i] = newElement
		}
		_checkInvariants()
	}

	mutating func insert<C: Collection>(
		contentsOf newElements: __owned C,
		at i: Int
	) where C.Element == Bool {
		precondition(i >= 0 && i <= count)
		let c = newElements.count
		guard c > 0 else { return }
		_extend(by: c)
		_copy(from: i ..< count - c, to: i + c)

		if C.self == BitArray.self {
			_copy(from: newElements as! BitArray, to: i)
		} else if C.self == BitArray.SubSequence.self {
			_copy(from: newElements as! BitArray.SubSequence, to: i)
		} else {
			_copy(from: newElements, to: i ..< i + c)
		}

		_checkInvariants()
	}

	mutating func insert(
		contentsOf newElements: __owned BitArray,
		at i: Int
	) {
		insert(contentsOf: newElements[...], at: i)
	}

	mutating func insert(
		contentsOf newElements: __owned BitArray.SubSequence,
		at i: Int
	) {
		let c = newElements.count
		guard c > 0 else { return }
		_extend(by: c)
		_copy(from: i ..< count - c, to: i + c)
		_copy(from: newElements, to: i)
		_checkInvariants()
	}
}

public extension BitArray {
	@discardableResult
	mutating func remove(at i: Int) -> Bool {
		let result = self[i]
		_copy(from: i + 1 ..< count, to: i)
		_removeLast()
		_checkInvariants()
		return result
	}

	mutating func removeSubrange(_ bounds: Range<Int>) {
		precondition(
			bounds.lowerBound >= 0 && bounds.upperBound <= count,
			"Bounds out of range"
		)
		_copy(
			from: Range(uncheckedBounds: (bounds.upperBound, count)),
			to: bounds.lowerBound
		)
		_removeLast(bounds.count)
		_checkInvariants()
	}

	mutating func _customRemoveLast() -> Bool? {
		precondition(_count > 0)
		let result = self[count - 1]
		_removeLast()
		_checkInvariants()
		return result
	}

	mutating func _customRemoveLast(_ n: Int) -> Bool {
		precondition(n >= 0 && n <= count)
		_removeLast(n)
		_checkInvariants()
		return true
	}

	@discardableResult
	mutating func removeFirst() -> Bool {
		precondition(_count > 0)
		let result = self[0]
		_copy(from: 1 ..< count, to: 0)
		_removeLast()
		_checkInvariants()
		return result
	}

	mutating func removeFirst(_ k: Int) {
		precondition(k >= 0 && k <= _count)
		_copy(from: k ..< count, to: 0)
		_removeLast(k)
		_checkInvariants()
	}

	mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
		_storage.removeAll(keepingCapacity: keepCapacity)
		_count = 0
		_checkInvariants()
	}
}
