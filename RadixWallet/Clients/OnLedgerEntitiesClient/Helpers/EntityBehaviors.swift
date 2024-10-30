
extension GatewayAPI.ComponentEntityRoleAssignments {
	/**
	 This extracts the appropriate `AssetBehavior`s from an instance of `ComponentEntityRoleAssignments`

	 __MOVEMENT BEHAVIORS__

	 For the behaviors related to movement, we first look at the current situation, using the logic under "Find performer" below,
	 applied to the two names `withdrawer` and `depositor`. If this results in anything other than `AllowAll`, then we add
	 the behavior `movementRestricted`.

	 If on the other hand it turns out that movement is *not* currently restricted, we look at who can change this in the future,
	 by finding the updaters for `withdrawer` and `depositor`, using the logic in "Find updaters" below. If at least one of
	 the names has `AllowAll`, we add the `movementRestrictableInFutureByAnyone` behavior. If at least one of them has `Protected`,
	 we add `movementRestrictableInFuture`.

	 __OTHER BEHAVIORS__

	 For the remaining behaviors the logic is as follows:

	 __Find performer:__ For a given "name" (`minter`, `freezer` etc) we find the "performer", i.e. who can perform the action *currently*:

	 1. Find the first entry in `self.entries` whose `roleKey.name` corresponds to `name`
	 2. Check if its `assignment` is `explicit` or points to `owner`
	 3. If it's explicit, we check which rule, out of`DenyAll`, `AllowAll` and `Protected`, that is set
	 4. For the `owner` case, we go to the root property `owner`, where its `rule` property should resolve to one of those three rules

	 __Find updaters:__ We also find the "updater" for the name, i.e. who can *change* the performer

	 1. For the same `entry`, we look at the `updaterRoles` property, which contains a list of names
	 2. For each of these names, we look up *their* corresponding entry and then the rule, like above

	 __Combine result:__ For our purposes here, we don't distinguish between performers and updaters, so we consider them together

	 1. Combine the performer and all updaters into a set, removing duplicates
	 2. If the set contains `AllowAll`, we add the "... by anyone" behavior
	 3. If the set contains `Protected` we add the plain behavior

	 At the end of all this, we check if we both `supplyIncreasable` and `.supplyDecreasable`, and if so, we replace them
	 with `.supplyFlexible`. We do the same check for the "by anyone" names.

	 Finally, if we end up with no behaviors, we return the `.simpleAsset` behavior instead.
	 */
	@Sendable func extractBehaviors() -> [AssetBehavior] {
		typealias AssignmentEntry = GatewayAPI.ComponentEntityRoleAssignmentEntry
		typealias ParsedName = GatewayAPI.RoleKey.ParsedName
		typealias ParsedAssignment = GatewayAPI.ComponentEntityRoleAssignmentEntry.ParsedAssignment

		func findEntry(_ name: GatewayAPI.RoleKey.ParsedName) -> AssignmentEntry? {
			entries.first { $0.roleKey.parsedName == name }
		}

		func resolvedOwner() -> ParsedAssignment.Explicit? {
			guard let dict = owner.value as? [String: Any] else { return nil }
			return ParsedAssignment.Explicit(dict["rule"] as Any)
		}

		func findAssigned(for parsedAssignment: ParsedAssignment) -> ParsedAssignment.Explicit? {
			switch parsedAssignment {
			case .owner:
				resolvedOwner()
			case let .explicit(explicit):
				explicit
			}
		}

		func performer(_ name: GatewayAPI.RoleKey.ParsedName) -> ParsedAssignment.Explicit? {
			guard let parsedAssignment = findEntry(name)?.parsedAssignment else { return nil }
			return findAssigned(for: parsedAssignment)
		}

		func updaters(_ name: GatewayAPI.RoleKey.ParsedName) -> Set<ParsedAssignment.Explicit?> {
			guard let updaters = findEntry(name)?.updaterRoles, !updaters.isEmpty else { return [nil] }

			// Lookup the corresponding assignments, ignoring unknown and empty values
			let parsedAssignments = Set(updaters.compactMap(\.parsedName).compactMap(findEntry).compactMap(\.parsedAssignment))

			return Set(parsedAssignments.map(findAssigned))
		}

		var result: Set<AssetBehavior> = []

		// Other names are checked individually, but without distinguishing between the role types
		func addBehavior(for rules: Set<ParsedAssignment.Explicit?>, ifSomeone: AssetBehavior, ifAnyone: AssetBehavior) {
			if rules.contains(.allowAll) {
				result.insert(ifAnyone)
			} else if rules.contains(.protected) {
				result.insert(ifSomeone)
			} else if rules.contains(nil) {
				loggerGlobal.warning("Failed to parse ComponentEntityRoleAssignments for \(ifSomeone)")
			}
		}

		// Movement behaviors: Withdrawer and depositor names are checked together, but we look
		// at the performer and updater role types separately
		let movers: Set = [performer(.withdrawer), performer(.depositor)]
		if movers != [.allowAll] {
			result.insert(.movementRestricted)
		} else {
			let moverUpdaters = updaters(.withdrawer).union(updaters(.depositor))
			addBehavior(for: moverUpdaters, ifSomeone: .movementRestrictableInFuture, ifAnyone: .movementRestrictableInFutureByAnyone)
		}

		// Other names are checked individually, but without distinguishing between the role types
		func addBehavior(for name: GatewayAPI.RoleKey.ParsedName, ifSomeone: AssetBehavior, ifAnyone: AssetBehavior) {
			let performersAndUpdaters = updaters(name).union([performer(name)])
			addBehavior(for: performersAndUpdaters, ifSomeone: ifSomeone, ifAnyone: ifAnyone)
		}

		addBehavior(for: .minter, ifSomeone: .supplyIncreasable, ifAnyone: .supplyIncreasableByAnyone)
		addBehavior(for: .burner, ifSomeone: .supplyDecreasable, ifAnyone: .supplyDecreasableByAnyone)
		addBehavior(for: .recaller, ifSomeone: .removableByThirdParty, ifAnyone: .removableByAnyone)
		addBehavior(for: .freezer, ifSomeone: .freezableByThirdParty, ifAnyone: .freezableByAnyone)
		addBehavior(for: .nonFungibleDataUpdater, ifSomeone: .nftDataChangeable, ifAnyone: .nftDataChangeableByAnyone)
		addBehavior(for: .metadataSetter, ifSomeone: .informationChangeable, ifAnyone: .informationChangeableByAnyone)

		// If there are no special behaviors, that means it's a "simple asset"
		if result.isEmpty {
			return [.simpleAsset]
		}

		// Finally we make some simplifying substitutions
		func substitute(_ source: Set<AssetBehavior>, with target: AssetBehavior) {
			if result.isSuperset(of: source) {
				result.subtract(source)
				result.insert(target)
			}
		}

		// If supply is both increasable and decreasable, then it's "flexible"
		substitute([.supplyIncreasableByAnyone, .supplyDecreasableByAnyone], with: .supplyFlexibleByAnyone)
		substitute([.supplyIncreasable, .supplyDecreasable], with: .supplyFlexible)

		return result.sorted()
	}
}

extension GatewayAPI.RoleKey {
	var parsedName: ParsedName? {
		.init(rawValue: name)
	}

	enum ParsedName: String, Hashable {
		case minter
		case burner
		case withdrawer
		case depositor
		case recaller
		case freezer
		case nonFungibleDataUpdater = "non_fungible_data_updater"
		case metadataLocker = "metadata_locker"
		case metadataSetter = "metadata_setter"

		case minterUpdater = "minter_updater"
		case burnerUpdater = "burner_updater"
		case withdrawerUpdater = "withdrawer_updater"
		case depositorUpdater = "depositor_updater"
		case recallerUpdater = "recaller_updater"
		case freezerUpdater = "freezer_updater"
		case nonFungibleDataUpdaterUpdater = "non_fungible_data_updater_updater"
		case metadataLockerUpdater = "metadata_locker_updater"
		case metadataSetterUpdater = "metadata_setter_updater"
	}
}

extension GatewayAPI.ComponentEntityRoleAssignmentEntry {
	var parsedAssignment: ParsedAssignment? {
		.init(assignment)
	}

	enum ParsedAssignment: Hashable {
		case owner
		case explicit(Explicit)

		enum Explicit: Hashable {
			case denyAll
			case allowAll
			case protected

			init?(_ explicitRule: Any) {
				guard let explicitRule = explicitRule as? [String: Any] else { return nil }
				guard let type = explicitRule["type"] as? String else { return nil }

				switch type {
				case "DenyAll":
					self = .denyAll
				case "AllowAll":
					self = .allowAll
				case "Protected":
					self = .protected
				default:
					return nil
				}
			}
		}

		init?(_ assignment: GatewayAPI.ComponentEntityRoleAssignmentEntryAssignment) {
			switch assignment.resolution {
			case .owner:
				guard assignment.explicitRule == nil else { return nil }
				self = .owner
			case .explicit:
				guard let explicitRule = assignment.explicitRule?.value else { return nil }
				guard let explicit = Explicit(explicitRule) else { return nil }
				self = .explicit(explicit)
			}
		}
	}
}
