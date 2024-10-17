import Foundation
import Sargon

extension DisplayName {
	var asNonEmpty: NonEmptyString {
		NonEmptyString(rawValue: value)!
	}

	init(nonEmpty: NonEmptyString) {
		self.init(value: nonEmpty.rawValue)
	}
}
