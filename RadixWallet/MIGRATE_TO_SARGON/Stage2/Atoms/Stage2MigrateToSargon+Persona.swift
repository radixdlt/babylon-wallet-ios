import Foundation
import Sargon

extension Persona {
	public mutating func hide() {
		entityFlags.append(.deletedByUser)
	}

	public mutating func unhide() {
		entityFlags.remove(.deletedByUser)
	}
}

extension Personas {
	public var nonHidden: Personas {
		filter(not(\.isHidden))
	}

	public var hidden: Personas {
		filter(\.isHidden)
	}
}
