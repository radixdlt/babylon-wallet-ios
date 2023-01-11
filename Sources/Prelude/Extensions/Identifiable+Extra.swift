public extension Identifiable where Self: RawRepresentable, RawValue: Hashable {
	var id: RawValue {
		rawValue
	}
}
