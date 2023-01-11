// MARK: - BitArray
public struct BitArray {
	@usableFromInline
	internal var _storage: [_Word]

	@usableFromInline
	internal var _count: UInt

	@usableFromInline
	internal init(_storage: [_Word], count: UInt) {
		assert(count <= _storage.count * _Word.capacity)
		assert(count > (_storage.count - 1) * _Word.capacity)
		self._storage = _storage
		self._count = count
	}

	@inline(__always)
	internal init(_storage: [_Word], count: Int) {
		self.init(_storage: _storage, count: UInt(count))
	}
}

extension BitArray {
	@inline(__always)
	func _read<R>(
		_ body: (_UnsafeHandle) throws -> R
	) rethrows -> R {
		try _storage.withUnsafeBufferPointer { words in
			let handle = _UnsafeHandle(
				words: words, count: _count, mutable: false
			)
			return try body(handle)
		}
	}

	@inline(__always)
	mutating func _update<R>(
		_ body: (inout _UnsafeHandle) throws -> R
	) rethrows -> R {
		defer {
			_checkInvariants()
		}
		return try _storage.withUnsafeMutableBufferPointer { words in
			var handle = _UnsafeHandle(words: words, count: _count, mutable: true)
			return try body(&handle)
		}
	}

	mutating func _removeLast() {
		assert(_count > 0)
		_count -= 1
		let bit = _BitPosition(_count).bit
		if bit == 0 {
			_storage.removeLast()
		} else {
			_storage[_storage.count - 1].remove(bit)
		}
	}

	mutating func _removeLast(_ n: Int) {
		assert(n >= 0 && n <= _count)
		guard n > 0 else { return }
		let wordCount = _Word.wordCount(forBitCount: _count - UInt(n))
		if wordCount < _storage.count {
			_storage.removeLast(_storage.count - wordCount)
		}
		_count -= UInt(n)
		let (word, bit) = _BitPosition(_count).split
		if bit > 0 {
			_storage[word].formIntersection(_Word(upTo: bit))
		}
	}

	mutating func _extend(by n: Int) {
		assert(n >= 0)
		guard n > 0 else { return }
		let orig = _storage.count
		let new = _Word.wordCount(forBitCount: _count + UInt(n))
		_storage.append(
			contentsOf: repeatElement(.empty, count: new - orig))
		_count += UInt(n)
	}
}
