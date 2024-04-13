import Foundation
import Sargon

extension Sargon.Persona: Identifiable {
	public typealias ID = IdentityAddress
	public var id: ID {
		address
	}
}
