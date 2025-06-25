// MARK: - DAppsDirectory
@Reducer
struct DAppsDirectory: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var allDapps: AllDapps.State = .init()
		var approvedDapps: AuthorizedDappsFeature.State = .init()
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case task
		case didSelectDapp(DApp.ID)
		case pullToRefreshStarted
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case allDapps(AllDapps.Action)
		case approvedDapps(AuthorizedDappsFeature.Action)
	}

	var body: some ReducerOf<Self> {
		Scope(state: \.allDapps, action: \.child.allDapps) {
			AllDapps()
		}

		Scope(state: \.approvedDapps, action: \.child.approvedDapps) {
			AuthorizedDappsFeature()
		}

		Reduce(core)
	}
}

extension DAppsDirectory {
	typealias DApps = IdentifiedArrayOf<DApp>
	typealias DAppsCategories = IdentifiedArrayOf<DAppsCategory>
	struct DApp: Sendable, Hashable, Identifiable {
		var id: DappDefinitionAddress {
			dAppDefinitionAddress
		}

		let dAppDefinitionAddress: DappDefinitionAddress
		let name: String
		let thumbnail: URL?
		let description: String?
		let tags: OrderedSet<OnLedgerTag>
		let category: DAppsDirectoryClient.DApp.Category
	}

	struct DAppsCategory: Identifiable, Equatable, Hashable {
		var id: DAppsDirectoryClient.DApp.Category {
			category
		}

		let category: DAppsDirectoryClient.DApp.Category
		let dApps: DApps
	}
}

extension DAppsDirectory.DApp {
	init(
		dAppDefinitionAddress: DappDefinitionAddress,
		dAppDetails: OnLedgerEntity.AssociatedDapp?,
		dAppDirectoryDetails: DAppsDirectoryClient.DApp?,
		approvedDappName: String?
	) {
		self.dAppDefinitionAddress = dAppDefinitionAddress
		self.name = dAppDetails?.metadata.name ?? approvedDappName ?? dAppDirectoryDetails?.name ?? L10n.DAppRequest.Metadata.unknownName
		self.thumbnail = dAppDetails?.metadata.iconURL
		self.description = dAppDetails?.metadata.description

		let tags = dAppDetails?.metadata.tags.nilIfEmpty ?? dAppDirectoryDetails?.tags ?? []
		self.tags = OrderedSet(tags.sorted())
		self.category = dAppDirectoryDetails?.dAppCategory ?? .other
	}
}

extension OrderedSet<OnLedgerTag> {
	var asFilterItems: IdentifiedArrayOf<ItemFilter<OnLedgerTag>> {
		self.elements.map {
			$0.asItemFilter(isActive: true)
		}.asIdentified()
	}
}

extension Loadable<DAppsDirectory.DAppsCategories> {
	func filtered(_ searchTerm: String, _ tags: OrderedSet<OnLedgerTag>) -> Self {
		compactMapValue {
			let filteredDapps = $0.dApps.filter { dApp in
				guard !tags.isEmpty else {
					return true
				}

				return dApp.tags.contains { tags.contains($0) }
			}
			.filter { dApp in
				if !searchTerm.isEmpty {
					dApp.name.range(of: searchTerm, options: .caseInsensitive) != nil ||
						dApp.description?.range(of: searchTerm, options: .caseInsensitive) != nil
				} else {
					true
				}
			}
			.asIdentified()

			guard !filteredDapps.isEmpty else {
				return nil
			}

			return DAppsDirectory.DAppsCategory(category: $0.category, dApps: filteredDapps)
		}
		.map { $0.sorted(by: \.category).asIdentified() }
	}
}
