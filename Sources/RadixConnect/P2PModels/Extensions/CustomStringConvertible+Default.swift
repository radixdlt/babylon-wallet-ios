import Foundation

extension CustomStringConvertible where Self: RawRepresentable, Self.RawValue == String {
	public var description: String { rawValue }
}

extension LocalizedError where Self: RawRepresentable, Self.RawValue == String {
	public var errorDescription: String? { rawValue }
}
