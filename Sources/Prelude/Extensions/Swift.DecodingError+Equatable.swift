import Foundation

// MARK: - Swift.DecodingError + Equatable
/// Make Swift.DecodingError `Equatable` so that we can use it in `DeserializeResponseFailure` and still
/// let `DeserializeResponseFailure` be `Equatable`.
extension Swift.DecodingError: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		switch (lhs, rhs) {
		/// An indication that a value of the given type could not be decoded because
		/// it did not match the type of what was found in the encoded payload.
		/// As associated values, this case contains the attempted type and context
		/// for debugging.
		case let (
			.typeMismatch(lhsType, lhsContext),
			.typeMismatch(rhsType, rhsContext)
		):
			return lhsType == rhsType && lhsContext == rhsContext

		/// An indication that a non-optional value of the given type was expected,
		/// but a null value was found.
		/// As associated values, this case contains the attempted type and context
		/// for debugging.
		case let (
			.valueNotFound(lhsType, lhsContext),
			.valueNotFound(rhsType, rhsContext)
		):
			return lhsType == rhsType && lhsContext == rhsContext

		/// An indication that a keyed decoding container was asked for an entry for
		/// the given key, but did not contain one.
		/// As associated values, this case contains the attempted key and context
		/// for debugging.
		case let (
			.keyNotFound(lhsKey, _),
			.keyNotFound(rhsKey, _)
		):
			return lhsKey.stringValue == rhsKey.stringValue

		/// An indication that the data is corrupted or otherwise invalid.
		/// As an associated value, this case contains the context for debugging.
		case let (
			.dataCorrupted(lhsContext),
			.dataCorrupted(rhsContext)
		):
			return lhsContext == rhsContext

		default: return false
		}
	}
}

// MARK: - Swift.DecodingError.Context + Equatable
extension Swift.DecodingError.Context: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.debugDescription == rhs.debugDescription
	}
}
