import Foundation
import Sargon

// MARK: - Sargon.Persona + Identifiable
extension Sargon.Persona: Identifiable {
	public typealias ID = IdentityAddress
	public var id: ID {
		address
	}

	public var networkID: NetworkID {
		networkId
	}
}

// MARK: - Sargon.Persona + EntityBaseProtocol
extension Sargon.Persona: EntityBaseProtocol {}
