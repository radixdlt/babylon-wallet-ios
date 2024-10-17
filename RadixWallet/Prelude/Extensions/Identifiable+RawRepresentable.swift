
extension Identifiable where Self: RawRepresentable, RawValue: Hashable, ID == RawValue {
	var id: ID { rawValue }
}

extension CustomStringConvertible where Self: RawRepresentable, RawValue == String {
	var description: String {
		rawValue
	}
}
