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
	public var nonHidden: Personas {
		filter(not(\.isHidden))
	}

	public var hiden: Personas {
		filter(\.isHidden)
	}
}
