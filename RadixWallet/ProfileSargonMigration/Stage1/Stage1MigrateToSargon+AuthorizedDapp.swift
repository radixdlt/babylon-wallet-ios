import Foundation
import Sargon

extension AuthorizedDapp: Identifiable {
	public typealias ID = DappDefinitionAddress
	public var id: ID {
		self.dappDefinitionAddress
	}

	public var networkID: NetworkID {
		networkId
	}

	public var dAppDefinitionAddress: DappDefinitionAddress {
		dappDefinitionAddress
	}
}
