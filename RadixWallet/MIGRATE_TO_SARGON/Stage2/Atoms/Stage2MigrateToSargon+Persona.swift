import Foundation
import Sargon

extension Persona {
	mutating func hide() {
		entityFlags.append(.deletedByUser)
	}

	mutating func unhide() {
		entityFlags.remove(.deletedByUser)
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
