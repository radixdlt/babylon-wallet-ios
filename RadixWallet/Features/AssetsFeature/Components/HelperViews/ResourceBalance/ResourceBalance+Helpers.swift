import Foundation

// MARK: - SendableAnyHashable
struct SendableAnyHashable: @unchecked Sendable, Hashable {
	let wrapped: AnyHashable

	init(wrapped: some Hashable & Sendable) {
		self.wrapped = .init(wrapped)
	}
}

// MARK: - ResourceBalance + Comparable
extension ResourceBalance: Comparable {
	static func < (lhs: Self, rhs: Self) -> Bool {
		switch (lhs.details, rhs.details) {
		case let (.fungible(lhsValue), .fungible(rhsValue)):
			if lhs.resource.resourceAddress == rhs.resource.resourceAddress {
				// If it's the same resource, sort by the amount
				order(lhs: lhsValue.amount.nominalAmount, rhs: rhsValue.amount.nominalAmount)
			} else {
				if lhs.resource.resourceAddress.isXRD {
					true
				} else if rhs.resource.resourceAddress.isXRD {
					false
				} else {
					// Else sort alphabetically by title, or failing that, address
					order(lhs: lhs.resource.metadata.name, rhs: rhs.resource.metadata.name) {
						lhs.resource.resourceAddress.address < rhs.resource.resourceAddress.address
					}
				}
			}
		case let (.nonFungible(lhsValue), .nonFungible(rhsValue)):
			if lhsValue.id.resourceAddress == rhsValue.id.resourceAddress {
				lhsValue.id.nonFungibleLocalId.toUserFacingString() < rhsValue.id.nonFungibleLocalId.toUserFacingString()
			} else {
				lhsValue.id.resourceAddress.description < rhsValue.id.resourceAddress.description
			}
		case let (.liquidStakeUnit(lhsValue), .liquidStakeUnit(rhsValue)):
			if lhsValue.validator.address == rhsValue.validator.address {
				if lhs.resource.resourceAddress == rhs.resource.resourceAddress {
					// If it's the same resource, sort by the amount
					order(lhs: lhsValue.amount, rhs: rhsValue.amount)
				} else {
					order(lhs: lhs.resource, rhs: rhs.resource)
				}
			} else {
				order(lhs: lhsValue.validator.metadata.name, rhs: rhsValue.validator.metadata.name) {
					// If it's the same validator (name), sort by the resource
					if lhs.resource.resourceAddress == rhs.resource.resourceAddress {
						// If it's the same resource, sort by the amount
						order(lhs: lhsValue.amount, rhs: rhsValue.amount)
					} else {
						order(lhs: lhs.resource, rhs: rhs.resource)
					}
				}
			}
		case let (.poolUnit(lhsValue), .poolUnit(rhsValue)):
			if lhs.resource == rhs.resource {
				// If it's the same resource, sort by the amount
				order(lhs: lhsValue.details.poolUnitResource.amount.nominalAmount, rhs: rhsValue.details.poolUnitResource.amount.nominalAmount)
			} else {
				// Else sort alphabetically by pool name, or failing that, address
				order(lhs: lhs.resource.fungibleResourceName, rhs: rhs.resource.fungibleResourceName) {
					lhs.resource.resourceAddress.address < rhs.resource.resourceAddress.address
				}
			}
		default:
			lhs.priority < rhs.priority
		}
	}

	private var priority: Int {
		switch details {
		case .fungible:
			0
		case .nonFungible:
			1
		case .liquidStakeUnit:
			2
		case .stakeClaimNFT:
			3
		case .poolUnit:
			4
		}
	}
}

// MARK: - ResourceBalance.Amount + Comparable
extension ResourceBalance.Amount: Comparable {
	static func < (lhs: Self, rhs: Self) -> Bool {
		order(lhs: lhs.amount, rhs: rhs.amount) {
			order(lhs: lhs.guaranteed, rhs: rhs.guaranteed)
		}
	}

	static let zero = ResourceBalance.Amount(0)
}

private func order(lhs: OnLedgerEntity.Resource, rhs: OnLedgerEntity.Resource) -> Bool {
	// Sort alphabetically by resource title, or failing that, address
	order(lhs: lhs.metadata.title, rhs: rhs.metadata.title) {
		lhs.resourceAddress.address < rhs.resourceAddress.address
	}
}

private func order<W: Comparable>(lhs: W?, rhs: W?, tieBreak: () -> Bool) -> Bool {
	switch (lhs, rhs) {
	case let (lhsValue?, rhsValue?):
		if lhs == rhs {
			tieBreak()
		} else {
			lhsValue < rhsValue
		}
	case (nil, _?):
		true
	case (_?, nil):
		false
	case (nil, nil):
		tieBreak()
	}
}

private func order(lhs: Decimal192?, rhs: Decimal192?) -> Bool {
	lhs ?? .min < rhs ?? .min
}
