import SwiftUI

extension ResourceBalance.ViewState.PoolUnit {
	public init(poolUnit: OnLedgerEntity.Account.PoolUnit, details: Loadable<OnLedgerEntitiesClient.OwnedResourcePoolDetails> = .idle) {
		self.init(
			resourcePoolAddress: poolUnit.resourcePoolAddress,
			poolUnitAddress: poolUnit.resource.resourceAddress,
			poolIcon: poolUnit.resource.metadata.iconURL,
			poolName: poolUnit.resource.metadata.fungibleResourceName,
			amount: nil,
			dAppName: details.dAppName,
			resources: details.map { .init(resources: $0) }
		)
	}
}

extension ResourceBalance.ViewState.Fungible {
	public static func xrd(balance: ResourceAmount, network: NetworkID) -> Self {
		.init(
			address: .xrd(on: network),
			icon: .token(.xrd),
			title: Constants.xrdTokenName,
			amount: .init(balance)
		)
	}
}

// MARK: - ResourceBalance.ViewState + Identifiable
extension ResourceBalance.ViewState: Identifiable {
	public var id: AnyHashable {
		self
	}
}

extension ResourceBalanceView {
	func withAuxiliary(spacing: CGFloat = 0, _ content: () -> some View) -> some View {
		HStack(spacing: 0) {
			self
				.layoutPriority(1)

			Spacer(minLength: spacing)

			content()
				.layoutPriority(-1)
		}
	}
}

// MARK: - EnvironmentValues

extension EnvironmentValues {
	/// The fallback string when the amount value is missing
	var missingFungibleAmountFallback: String? {
		get { self[MissingFungibleAmountKey.self] }
		set { self[MissingFungibleAmountKey.self] = newValue }
	}
}

// MARK: - MissingFungibleAmountKey
private struct MissingFungibleAmountKey: EnvironmentKey {
	static let defaultValue: String? = nil
}

extension EnvironmentValues {
	/// The fallback string when the amount value is missing
	var resourceBalanceHideDetails: Bool {
		get { self[ResourceBalanceHideDetailsKey.self] }
		set { self[ResourceBalanceHideDetailsKey.self] = newValue }
	}
}

// MARK: - ResourceBalanceHideDetailsKey
private struct ResourceBalanceHideDetailsKey: EnvironmentKey {
	static let defaultValue: Bool = false
}

extension EnvironmentValues {
	var resourceBalanceHideFiatValue: Bool {
		get { self[ResourceBalanceHideFiatValue.self] }
		set { self[ResourceBalanceHideFiatValue.self] = newValue }
	}
}

// MARK: - ResourceBalanceHideFiatValue
private struct ResourceBalanceHideFiatValue: EnvironmentKey {
	static let defaultValue: Bool = false
}
