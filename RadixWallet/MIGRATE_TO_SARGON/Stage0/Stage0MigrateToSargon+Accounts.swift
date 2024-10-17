import Foundation
import IdentifiedCollections
import Sargon

typealias Accounts = IdentifiedArrayOf<Account>
typealias Personas = IdentifiedArrayOf<Persona>
typealias ProfileNetworks = IdentifiedArrayOf<ProfileNetwork>
typealias AssetsExceptionList = IdentifiedArrayOf<AssetException>
typealias DepositorsAllowList = IdentifiedArrayOf<ResourceOrNonFungible>
typealias FactorSources = IdentifiedArrayOf<FactorSource>
typealias P2PLinks = IdentifiedArrayOf<P2PLink>
typealias AuthorizedDapps = IdentifiedArrayOf<AuthorizedDapp>
typealias ReferencesToAuthorizedPersonas = IdentifiedArrayOf<AuthorizedPersonaSimple>
typealias DetailedAuthorizedPersonas = IdentifiedArrayOf<AuthorizedPersonaDetailed>
typealias AccountsForDisplay = IdentifiedArrayOf<AccountForDisplay>
typealias Gateways = IdentifiedArrayOf<Gateway>

typealias EntityFlags = IdentifiedArrayOf<EntityFlag>

extension Account {
	var entityFlags: EntityFlags {
		get { flags.asIdentified() }
		set {
			flags = newValue.elements
		}
	}
}

extension Persona {
	var entityFlags: EntityFlags {
		get { flags.asIdentified() }
		set {
			flags = newValue.elements
		}
	}
}
