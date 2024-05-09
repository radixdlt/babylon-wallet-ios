import Foundation
import IdentifiedCollections
import Sargon

public typealias Accounts = IdentifiedArrayOf<Account>
public typealias Personas = IdentifiedArrayOf<Persona>
public typealias ProfileNetworks = IdentifiedArrayOf<ProfileNetwork>
public typealias AssetsExceptionList = IdentifiedArrayOf<AssetException>
public typealias DepositorsAllowList = IdentifiedArrayOf<ResourceOrNonFungible>
public typealias FactorSources = IdentifiedArrayOf<FactorSource>
public typealias P2PLinks = IdentifiedArrayOf<P2PLink>
public typealias AuthorizedDapps = IdentifiedArrayOf<AuthorizedDapp>
public typealias ReferencesToAuthorizedPersonas = IdentifiedArrayOf<AuthorizedPersonaSimple>
public typealias DetailedAuthorizedPersonas = IdentifiedArrayOf<AuthorizedPersonaDetailed>
public typealias AccountsForDisplay = IdentifiedArrayOf<AccountForDisplay>
public typealias Gateways = IdentifiedArrayOf<Gateway>

public typealias EntityFlags = IdentifiedArrayOf<EntityFlag>

extension Account {
	public var entityFlags: EntityFlags {
		get { flags.asIdentified() }
		set {
			flags = newValue.elements
		}
	}
}

extension Persona {
	public var entityFlags: EntityFlags {
		get { flags.asIdentified() }
		set {
			flags = newValue.elements
		}
	}
}
