import Foundation
import Sargon

extension Persona {
	mutating func hide() {
		entityFlags.append(.hiddenByUser)
	}

	mutating func unhide() {
		entityFlags.remove(.hiddenByUser)
	}
}

extension Personas {
	var nonHidden: Personas {
		filter(not(\.isHidden))
	}

	var hidden: Personas {
		filter(\.isHidden)
	}
}
