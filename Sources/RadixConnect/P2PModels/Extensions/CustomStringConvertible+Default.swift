import Foundation

public extension CustomStringConvertible where Self: RawRepresentable, Self.RawValue == String {
	var description: String { rawValue }
}

public extension LocalizedError where Self: RawRepresentable, Self.RawValue == String {
	var errorDescription: String? { rawValue }
}
