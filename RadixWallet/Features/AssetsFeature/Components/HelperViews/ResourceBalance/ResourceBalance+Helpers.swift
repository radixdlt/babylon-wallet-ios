import Foundation

// MARK: - SendableAnyHashable
struct SendableAnyHashable: @unchecked Sendable, Hashable {
	let wrapped: AnyHashable

	init(wrapped: some Hashable & Sendable) {
		self.wrapped = .init(wrapped)
	}
}

// MARK: - KnownResourceBalance + Comparable
extension KnownResourceBalance: Comparable {
	static func < (lhs: Self, rhs: Self) -> Bool {
		switch (lhs.details, rhs.details) {
		case let (.fungible(lhsValue), .fungible(rhsValue)):
			if lhs.resource.resourceAddress == rhs.resource.resourceAddress {
				// If it's the same resource, sort by the amount
				return order(lhs: lhsValue.amount.exactAmount?.nominalAmount, rhs: rhsValue.amount.exactAmount?.nominalAmount)
			} else {
				if lhs.resource.resourceAddress.isXRD {
					return true
				} else if rhs.resource.resourceAddress.isXRD {
					return false
				} else {
					// Else sort alphabetically by title, or failing that, address
					return order(lhs: lhs.resource.metadata.name, rhs: rhs.resource.metadata.name) {
						lhs.resource.resourceAddress.address < rhs.resource.resourceAddress.address
					}
				}
			}
		case let (.nonFungible(lhsValue), .nonFungible(rhsValue)):
			guard case let .token(lhsToken) = lhsValue, case let .token(rhsToken) = rhsValue else { return false }

			if lhsToken.id.resourceAddress == rhsToken.id.resourceAddress {
				return lhsToken.id.nonFungibleLocalId.toUserFacingString() < rhsToken.id.nonFungibleLocalId.toUserFacingString()
			} else {
				return lhsToken.id.resourceAddress.description < rhsToken.id.resourceAddress.description
			}
		case let (.liquidStakeUnit(lhsValue), .liquidStakeUnit(rhsValue)):
			if lhsValue.validator.address == rhsValue.validator.address {
				if lhs.resource.resourceAddress == rhs.resource.resourceAddress {
					// If it's the same resource, sort by the amount
					return order(lhs: lhsValue.amount.exactAmount?.nominalAmount ?? 0, rhs: rhsValue.amount.exactAmount?.nominalAmount ?? 0)
				} else {
					return order(lhs: lhs.resource, rhs: rhs.resource)
				}
			} else {
				return order(lhs: lhsValue.validator.metadata.name, rhs: rhsValue.validator.metadata.name) {
					// If it's the same validator (name), sort by the resource
					if lhs.resource.resourceAddress == rhs.resource.resourceAddress {
						// If it's the same resource, sort by the amount
						order(lhs: lhsValue.amount.exactAmount?.nominalAmount ?? 0, rhs: rhsValue.amount.exactAmount?.nominalAmount ?? 0)
					} else {
						order(lhs: lhs.resource, rhs: rhs.resource)
					}
				}
			}
		case let (.poolUnit(lhsValue), .poolUnit(rhsValue)):
			if lhs.resource == rhs.resource {
				// If it's the same resource, sort by the amount
				return order(lhs: lhsValue.details.poolUnitResource.amount.exactAmount?.nominalAmount ?? 0, rhs: rhsValue.details.poolUnitResource.amount.exactAmount?.nominalAmount ?? 0)
			} else {
				// Else sort alphabetically by pool name, or failing that, address
				return order(lhs: lhs.resource.fungibleResourceName, rhs: rhs.resource.fungibleResourceName) {
					lhs.resource.resourceAddress.address < rhs.resource.resourceAddress.address
				}
			}
		default:
			return lhs.priority < rhs.priority
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
