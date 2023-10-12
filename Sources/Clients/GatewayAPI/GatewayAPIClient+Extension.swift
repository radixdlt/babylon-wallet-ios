import AnyCodable
import EngineKit
import Foundation
import Prelude
import SharedModels

extension GatewayAPIClient {
	@Sendable
	public func fetchAllFungibleResources(
		_ entityDetails: GatewayAPI.StateEntityDetailsResponseItem,
		ledgerState: GatewayAPI.LedgerState
	) async throws -> [GatewayAPI.FungibleResourcesCollectionItem] {
		guard let firstPage = entityDetails.fungibleResources else {
			return [GatewayAPI.FungibleResourcesCollectionItem]()
		}

		guard let nextPageCursor = firstPage.nextCursor else {
			return firstPage.items
		}

		let additionalItems = try await fetchAllPaginatedItems(
			cursor: PageCursor(ledgerState: ledgerState, nextPageCursor: nextPageCursor),
			fetchFungibleResourcePage(entityDetails.address)
		)

		return firstPage.items + additionalItems
	}

	// FIXME: Similar function to the above, maybe worth extracting in a single function?
	@Sendable
	public func fetchAllNonFungibleResources(
		_ entityDetails: GatewayAPI.StateEntityDetailsResponseItem,
		ledgerState: GatewayAPI.LedgerState
	) async throws -> [GatewayAPI.NonFungibleResourcesCollectionItem] {
		guard let firstPage = entityDetails.nonFungibleResources else {
			return [GatewayAPI.NonFungibleResourcesCollectionItem]()
		}

		guard let nextPageCursor = firstPage.nextCursor else {
			return firstPage.items
		}

		let additionalItems = try await fetchAllPaginatedItems(
			cursor: PageCursor(ledgerState: ledgerState, nextPageCursor: nextPageCursor),
			fetchNonFungibleResourcePage(entityDetails.address)
		)

		return firstPage.items + additionalItems
	}

	public func fetchFungibleResourcePage(
		_ entityAddress: String
	) -> @Sendable (PageCursor?) async throws -> PaginatedResourceResponse<GatewayAPI.FungibleResourcesCollectionItem> {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return { pageCursor in
			let request = GatewayAPI.StateEntityFungiblesPageRequest(
				atLedgerState: pageCursor?.ledgerState.selector,
				cursor: pageCursor?.nextPageCursor,
				address: entityAddress,
				aggregationLevel: .vault,
				optIns: .init(explicitMetadata: Array(Set<EntityMetadataKey>.resourceMetadataKeys.map(\.rawValue)))
			)
			let response = try await gatewayAPIClient.getEntityFungiblesPage(request)

			return .init(
				loadedItems: response.items,
				totalCount: response.totalCount,
				cursor: response.nextCursor.map {
					PageCursor(ledgerState: response.ledgerState, nextPageCursor: $0)
				}
			)
		}
	}

	public func fetchNonFungibleResourcePage(
		_ accountAddress: String
	) -> @Sendable (PageCursor?) async throws -> PaginatedResourceResponse<GatewayAPI.NonFungibleResourcesCollectionItem> {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return { pageCursor in
			let request = GatewayAPI.StateEntityNonFungiblesPageRequest(
				atLedgerState: pageCursor?.ledgerState.selector,
				cursor: pageCursor?.nextPageCursor,
				address: accountAddress,
				aggregationLevel: .vault,
				optIns: .init(
					nonFungibleIncludeNfids: true,
					explicitMetadata: .init(Array(Set<EntityMetadataKey>.resourceMetadataKeys.map(\.rawValue)))
				)
			)
			let response = try await gatewayAPIClient.getEntityNonFungiblesPage(request)

			return .init(
				loadedItems: response.items,
				totalCount: response.totalCount,
				cursor: response.nextCursor.map {
					PageCursor(ledgerState: response.ledgerState, nextPageCursor: $0)
				}
			)
		}
	}

	public func fetchEntityNonFungibleResourceIdsPage(
		_ accountAddress: String,
		resourceAddress: String,
		vaultAddress: String
	) -> @Sendable (PageCursor?) async throws -> PaginatedResourceResponse<String> {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return { pageCursor in
			let request = GatewayAPI.StateEntityNonFungibleIdsPageRequest(
				atLedgerState: pageCursor?.ledgerState.selector,
				cursor: pageCursor?.nextPageCursor,
				address: accountAddress,
				vaultAddress: vaultAddress,
				resourceAddress: resourceAddress
			)
			let response = try await gatewayAPIClient.getEntityNonFungibleIdsPage(request)

			return .init(
				loadedItems: response.items,
				totalCount: response.totalCount,
				cursor: response.nextCursor.map {
					PageCursor(ledgerState: response.ledgerState, nextPageCursor: $0)
				}
			)
		}
	}
}

// MARK: - Pagination
extension GatewayAPIClient {
	/// A page cursor is required to have the `nextPageCurosr` itself, as well the `ledgerState` of the previous page.
	public struct PageCursor: Hashable, Sendable {
		public let ledgerState: GatewayAPI.LedgerState
		public let nextPageCursor: String

		public init(ledgerState: GatewayAPI.LedgerState, nextPageCursor: String) {
			self.ledgerState = ledgerState
			self.nextPageCursor = nextPageCursor
		}
	}

	public struct PaginatedResourceResponse<Resource: Sendable>: Sendable {
		public let loadedItems: [Resource]
		public let totalCount: Int64?
		public let cursor: PageCursor?

		public init(loadedItems: [Resource], totalCount: Int64?, cursor: PageCursor?) {
			self.loadedItems = loadedItems
			self.totalCount = totalCount
			self.cursor = cursor
		}
	}

	/// Recursively fetches all of the pages for a given paginated request.
	///
	/// Provide an initial page cursor if needed to load the all the items starting with a given page
	@Sendable
	public func fetchAllPaginatedItems<Item>(
		cursor: PageCursor?,
		_ paginatedRequest: @Sendable @escaping (_ cursor: PageCursor?) async throws -> PaginatedResourceResponse<Item>
	) async throws -> [Item] {
		@Sendable
		func fetchAllPaginatedItems(
			collectedResources: PaginatedResourceResponse<Item>?
		) async throws -> [Item] {
			/// Finish when some items where loaded and the nextPageCursor is nil.
			if let collectedResources, collectedResources.cursor == nil {
				return collectedResources.loadedItems
			}

			/// We can request here with nil nextPageCursor, as the first page will not have a cursor.
			let response = try await paginatedRequest(collectedResources?.cursor)
			let oldItems = collectedResources?.loadedItems ?? []
			let allItems = oldItems + response.loadedItems

			let nextPageCursor: PageCursor? = {
				// Safeguard: Don't rely only on the gateway returning nil for the next page cursor,
				// if happened to load an empty page, or all items were loaded - next page cursor is nil.
				if response.loadedItems.isEmpty || allItems.count == response.totalCount.map(Int.init) {
					return nil
				}

				return response.cursor
			}()

			let result = PaginatedResourceResponse(loadedItems: allItems, totalCount: response.totalCount, cursor: nextPageCursor)
			return try await fetchAllPaginatedItems(collectedResources: result)
		}

		return try await fetchAllPaginatedItems(
			collectedResources: cursor.map {
				PaginatedResourceResponse(loadedItems: [], totalCount: nil, cursor: $0)
			}
		)
	}
}

extension GatewayAPI.EntityMetadataCollection {
	@Sendable public func extractTags() -> [AssetTag] {
		tags?.compactMap(NonEmptyString.init(rawValue:)).map(AssetTag.init) ?? []
	}
}

// FIXME: This logic should not be here, will probably move to OnLedgerEntitiesClient.
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
	@Sendable public func extractBehaviors() -> [AssetBehavior] {
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
				return resolvedOwner()
			case let .explicit(explicit):
				return explicit
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
