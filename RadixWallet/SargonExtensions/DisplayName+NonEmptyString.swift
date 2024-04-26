import Foundation
import Sargon

extension DisplayName {
	public var asNonEmpty: NonEmptyString {
		NonEmptyString(rawValue: value)!
	}

	public init(nonEmpty: NonEmptyString) {
		self.init(value: nonEmpty.rawValue)
	}
}
