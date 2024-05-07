//
//  Stage0MigrateToSargon+Accounts.swift
//  RadixWallet
//
//  Created by Alexander Cyon on 2024-05-07.
//

import Foundation
import Sargon
import IdentifiedCollections

public typealias Accounts = IdentifiedArrayOf<Account>

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
