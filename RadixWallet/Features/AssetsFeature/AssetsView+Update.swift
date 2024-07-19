import ComposableArchitecture
import SwiftUI

extension AssetsView {
	typealias NFTRowsToRefresh = [ResourceAddress]

	func updateFromPortfolio(
		state: inout State,
		from portfolio: AccountPortfoliosClient.AccountPortfolio
	) -> NFTRowsToRefresh {
		let mode = state.mode
		let xrd = portfolio.account.fungibleResources.xrdResource.map { token in
			let updatedRow = state.resources.fungibleTokenList?.updatedRow(token: token, for: .xrd)

			return updatedRow ?? FungibleAssetList.Section.Row.State(
				xrdToken: token,
				isSelected: mode.xrdRowSelected
			)
		}
		let nonXrd = portfolio.account.fungibleResources.nonXrdResources.map { token in
			let updatedRow = state.resources.fungibleTokenList?.updatedRow(token: token, for: .nonXrd)

			return updatedRow ?? FungibleAssetList.Section.Row.State(
				nonXRDToken: token,
				isSelected: mode.nonXrdRowSelected(token.resourceAddress)
			)
		}
		.asIdentified()

		let nfts = portfolio.account.nonFungibleResources.map { resource in
			let updatedRow = state.resources.nonFungibleTokenList?.updatedRow(resource: resource)

			return updatedRow ?? NonFungibleAssetList.Row.State(
				accountAddress: portfolio.account.address,
				resource: resource,
				disabled: mode.selectedAssets?.disabledNFTs ?? [],
				selectedAssets: mode.nftRowSelectedAssets(resource.resourceAddress)
			)
		}
		let nftRowsToRefresh: [ResourceAddress] = portfolio.account.nonFungibleResources.compactMap { resource in
			state.resources.nonFungibleTokenList?.rows.first {
				$0.id == resource.resourceAddress &&
					$0.resource.nonFungibleIdsCount != resource.nonFungibleIdsCount &&
					$0.isExpanded
			}?.id
		}

		let fungibleTokenList: FungibleAssetList.State? = {
			var sections: IdentifiedArrayOf<FungibleAssetList.Section.State> = []
			if let xrd {
				sections.append(.init(id: .xrd, rows: [xrd]))
			}

			if !nonXrd.isEmpty {
				sections.append(.init(id: .nonXrd, rows: nonXrd))
			}

			guard !sections.isEmpty else {
				return nil
			}

			return .init(sections: sections)
		}()

		state.accountPortfolio.refresh(from: .success(portfolio))

		let poolUnits = portfolio.account.poolUnitResources.poolUnits
		let poolUnitList: PoolUnitsList.State? = poolUnits.isEmpty ? nil : .init(
			poolUnits: poolUnits.map { poolUnit in
				let resourceDetails = state.accountPortfolio.poolUnitDetails.flatten().flatMap {
					$0.first { poolUnit.resourcePoolAddress == $0.address }.map(Loadable.success) ?? .loading
				}
				let updatedPoolUnit = state.resources.poolUnitsList?.updatedPoolUnit(poolUnit: poolUnit, resourceDetails: resourceDetails)

				return updatedPoolUnit ?? PoolUnitsList.State.PoolUnitState(
					poolUnit: poolUnit,
					resourceDetails: resourceDetails,
					isSelected: mode.nonXrdRowSelected(poolUnit.resource.resourceAddress)
				)
			}.asIdentified()
		)

		let stakes = portfolio.account.poolUnitResources.radixNetworkStakes

		let stakeUnitList: StakeUnitList.State? = {
			guard !stakes.isEmpty else { return nil }

			let stakeUnitDetails = state.accountPortfolio.stakeUnitDetails.flatten()
			if let stakeUnitList = state.resources.stakeUnitList {
				return .init(
					account: stakeUnitList.account,
					selectedLiquidStakeUnits: stakeUnitList.selectedLiquidStakeUnits,
					selectedStakeClaimTokens: stakeUnitList.selectedStakeClaimTokens,
					stakeUnitDetails: stakeUnitDetails
				)
			} else {
				return .init(
					account: portfolio.account,
					selectedLiquidStakeUnits: mode.selectedAssets.map { assets in
						let stakeUnitResources = stakes.map(\.stakeUnitResource)
						return assets
							.fungibleResources
							.nonXrdResources
							.filter(stakeUnitResources.contains)
							.asIdentified()
					},
					selectedStakeClaimTokens:
					mode.isSelection ?
						stakes
						.compactMap(\.stakeClaimResource)
						.reduce(into: StakeUnitList.SelectedStakeClaimTokens()) { dict, resource in
							if let selectedtokens = mode.nftRowSelectedAssets(resource.resourceAddress)?.elements.asIdentified() {
								dict[resource] = selectedtokens
							}
						} : nil,
					stakeUnitDetails: stakeUnitDetails
				)
			}
		}()

		state.totalFiatWorth.refresh(from: portfolio.totalFiatWorth)
		state.resources = .init(
			fungibleTokenList: fungibleTokenList,
			nonFungibleTokenList: !nfts.isEmpty ? .init(rows: nfts.asIdentified()) : nil,
			stakeUnitList: stakeUnitList,
			poolUnitsList: poolUnitList
		)

		return nftRowsToRefresh
	}
}

extension AccountPortfoliosClient.AccountPortfolio {
	mutating func refresh(from portfolio: AccountPortfoliosClient.AccountPortfolio) {
		self.account = portfolio.account
		self.isCurrencyAmountVisible = portfolio.isCurrencyAmountVisible
		self.fiatCurrency = portfolio.fiatCurrency
		self.stakeUnitDetails.refresh(from: portfolio.stakeUnitDetails)
		self.poolUnitDetails.refresh(from: portfolio.poolUnitDetails)
	}
}

extension Loadable where Value == AccountPortfoliosClient.AccountPortfolio {
	mutating func refresh(from portfolio: Loadable<Value>) {
		self.refresh(from: portfolio, valueChangeMap: { old, new in
			var old = old
			old.refresh(from: new)
			return old
		})
	}
}

extension FungibleAssetList.State {
	public mutating func updatedRow(
		token: OnLedgerEntity.OwnedFungibleResource,
		for sectionID: FungibleAssetList.Section.State.ID
	) -> FungibleAssetList.Section.Row.State? {
		guard
			let section = sections.first(where: { $0.id == sectionID }),
			var row = section.rows.first(where: { $0.id == token.resourceAddress })
		else { return nil }

		row.token = token

		return row
	}
}

extension NonFungibleAssetList.State {
	public mutating func updatedRow(resource: OnLedgerEntity.OwnedNonFungibleResource) -> NonFungibleAssetList.Row.State? {
		guard var row = rows.first(where: { $0.id == resource.resourceAddress }) else { return nil }
		row.resource = resource
		return row
	}
}

extension PoolUnitsList.State {
	public mutating func updatedPoolUnit(
		poolUnit: OnLedgerEntity.OnLedgerAccount.PoolUnit,
		resourceDetails: Loadable<OnLedgerEntitiesClient.OwnedResourcePoolDetails>
	) -> PoolUnitsList.State.PoolUnitState? {
		guard var poolUnitState = poolUnits.first(where: { $0.id == poolUnit.resourcePoolAddress }) else { return nil }

		poolUnitState.poolUnit = poolUnit
		poolUnitState.resourceDetails = resourceDetails

		return poolUnitState
	}
}
