import Foundation
import Sargon

extension Persona {
	public mutating func hide() {
		flags.append(.deletedByUser)
	}

	public mutating func unhide() {
		flags.remove(.deletedByUser)
	}
}

extension Personas {
	public var nonHidden: IdentifiedArrayOf<Persona> {
		filter(not(\.isHidden)).asIdentified()
	}

	public var hiden: IdentifiedArrayOf<Persona> {
		filter(\.isHidden).asIdentified()
	}
}
