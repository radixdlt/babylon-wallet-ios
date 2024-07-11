extension AssetsView.State {
	/// Computed property of currently selected assets
	public var selectedAssets: Mode.SelectedAssets? {
		guard case .selection = mode else { return nil }

		let selectedLiquidStakeUnits = resources.stakeUnitList?.selectedLiquidStakeUnits ?? []

		let selectedPoolUnitTokens = resources.poolUnitsList?.poolUnits
			.map(SelectedResourceProvider.init)
			.compactMap(\.selectedResource) ?? []

		let selectedXRDResource = resources.fungibleTokenList?.sections[id: .xrd]?
			.rows
			.first
			.map(SelectedResourceProvider.init)
			.flatMap(\.selectedResource)

		let selectedNonXrdResources = resources.fungibleTokenList?.sections[id: .nonXrd]?.rows
			.map(SelectedResourceProvider.init)
			.compactMap(\.selectedResource) ?? []

		let selectedNonFungibleResources = resources.nonFungibleTokenList?.rows.compactMap(NonFungibleTokensPerResourceProvider.init) ?? []
		let selectedStakeClaims = resources.stakeUnitList?.selectedStakeClaimTokens?.map { resource, tokens in
			NonFungibleTokensPerResourceProvider(selectedAssets: .init(tokens), resource: resource)
		} ?? []

		let selectedFungibleResources = OnLedgerEntity.OwnedFungibleResources(
			xrdResource: selectedXRDResource,
			nonXrdResources: selectedNonXrdResources + selectedLiquidStakeUnits + selectedPoolUnitTokens
		)

		let selectedNonFungibleTokensPerResource =
			(selectedNonFungibleResources + selectedStakeClaims)
				.compactMap(\.nonFungibleTokensPerResource)

		guard
			selectedFungibleResources.xrdResource != nil
			|| !selectedFungibleResources.nonXrdResources.isEmpty
			|| !selectedNonFungibleTokensPerResource.isEmpty
		else {
			return nil
		}

		return .init(
			fungibleResources: selectedFungibleResources,
			nonFungibleResources: IdentifiedArrayOf(uniqueElements: selectedNonFungibleTokensPerResource),
			disabledNFTs: mode.selectedAssets?.disabledNFTs ?? []
		)
	}

	public var chooseButtonTitle: String {
		guard let selectedAssets else {
			return L10n.AssetTransfer.AddAssets.buttonAssetsNone
		}

		if selectedAssets.assetsCount == 1 {
			return L10n.AssetTransfer.AddAssets.buttonAssetsOne
		}

		return L10n.AssetTransfer.AddAssets.buttonAssets(selectedAssets.assetsCount)
	}
}

// MARK: - AssetsView.State.Mode
import ComposableArchitecture
import SwiftUI

// MARK: - AssetsView.State.Mode
extension AssetsView.State {
	public enum Mode: Hashable, Sendable {
		public struct SelectedAssets: Hashable, Sendable {
			public struct NonFungibleTokensPerResource: Hashable, Sendable, Identifiable {
				public var id: ResourceAddress {
					resourceAddress
				}

				public let resourceAddress: ResourceAddress
				public let resourceImage: URL?
				public let resourceName: String?
				public let atLedgerState: AtLedgerState
				public var tokens: IdentifiedArrayOf<OnLedgerEntity.NonFungibleToken>

				public init(
					resourceAddress: ResourceAddress,
					resourceImage: URL?,
					resourceName: String?,
					atLedgerState: AtLedgerState,
					tokens: IdentifiedArrayOf<OnLedgerEntity.NonFungibleToken>
				) {
					self.resourceAddress = resourceAddress
					self.resourceImage = resourceImage
					self.resourceName = resourceName
					self.atLedgerState = atLedgerState
					self.tokens = tokens
				}
			}

			public var fungibleResources: OnLedgerEntity.OwnedFungibleResources
			public var nonFungibleResources: IdentifiedArrayOf<NonFungibleTokensPerResource>
			public var disabledNFTs: Set<NonFungibleAssetList.Row.State.AssetID>

			public init(
				fungibleResources: OnLedgerEntity.OwnedFungibleResources = .init(),
				nonFungibleResources: IdentifiedArrayOf<NonFungibleTokensPerResource> = [],
				disabledNFTs: Set<NonFungibleAssetList.Row.State.AssetID>
			) {
				self.fungibleResources = fungibleResources
				self.nonFungibleResources = nonFungibleResources
				self.disabledNFTs = disabledNFTs
			}

			public var assetsCount: Int {
				fungibleResources.nonXrdResources.count +
					nonFungibleResources.map(\.tokens.count).reduce(0, +) +
					(fungibleResources.xrdResource != nil ? 1 : 0)
			}
		}

		case normal
		case selection(SelectedAssets)

		public var selectedAssets: SelectedAssets? {
			switch self {
			case .normal:
				nil
			case let .selection(assets):
				assets
			}
		}

		public var isSelection: Bool {
			if case .selection = self {
				return true
			}
			return false
		}

		var xrdRowSelected: Bool? {
			selectedAssets.map { $0.fungibleResources.xrdResource != nil }
		}

		func nonXrdRowSelected(_ resource: ResourceAddress) -> Bool? {
			selectedAssets?.fungibleResources.nonXrdResources.contains { $0.resourceAddress == resource }
		}

		func nftRowSelectedAssets(_ resource: ResourceAddress) -> OrderedSet<OnLedgerEntity.NonFungibleToken>? {
			selectedAssets.map { OrderedSet($0.nonFungibleResources[id: resource]?.tokens.elements ?? []) }
		}
	}
}

// MARK: - SelectedResourceProvider
private struct SelectedResourceProvider<Resource> {
	let isSelected: Bool?
	let resource: Resource

	var selectedResource: Resource? {
		isSelected.flatMap { $0 ? resource : nil }
	}
}

extension SelectedResourceProvider<OnLedgerEntity.OwnedFungibleResource> {
	init(with row: FungibleAssetList.Section.Row.State) {
		self.init(
			isSelected: row.isSelected,
			resource: row.token
		)
	}

	init(with poolUnit: PoolUnitsList.State.PoolUnitState) {
		self.init(
			isSelected: poolUnit.isSelected,
			resource: poolUnit.poolUnit.resource
		)
	}
}

// MARK: - NonFungibleTokensPerResourceProvider
private struct NonFungibleTokensPerResourceProvider {
	let selectedAssets: OrderedSet<OnLedgerEntity.NonFungibleToken>?
	let resource: OnLedgerEntity.OwnedNonFungibleResource?

	var nonFungibleTokensPerResource: AssetsView.State.Mode.SelectedAssets.NonFungibleTokensPerResource? {
		selectedAssets.flatMap { selectedAssets -> AssetsView.State.Mode.SelectedAssets.NonFungibleTokensPerResource? in
			guard
				let resource,
				!selectedAssets.isEmpty
			else {
				return nil
			}

			return .init(
				resourceAddress: resource.resourceAddress,
				resourceImage: resource.metadata.iconURL,
				resourceName: resource.metadata.title,
				atLedgerState: resource.atLedgerState,
				tokens: .init(uncheckedUniqueElements: selectedAssets)
			)
		}
	}
}

extension NonFungibleTokensPerResourceProvider {
	init(with row: NonFungibleAssetList.Row.State) {
		self.init(
			selectedAssets: row.selectedAssets,
			resource: row.resource
		)
	}
}
