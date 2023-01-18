import Foundation

// MARK: - BDouble + Sendable
extension BDouble: @unchecked Sendable {}

// MARK: - BDouble.Error
public extension BDouble {
	enum Error: Swift.Error {
		case initFromDecimalStringFailed
	}
}
