import Foundation

extension Identifiable where Self: RawRepresentable, RawValue: Hashable, ID == RawValue {
	public var id: ID { rawValue }
}

extension CustomStringConvertible where Self: RawRepresentable, RawValue == String {
	public var description: String {
		rawValue
	}
}
