extension Slice {
	var _bounds: Range<Index> {
		Range(uncheckedBounds: (startIndex, endIndex))
	}
}
