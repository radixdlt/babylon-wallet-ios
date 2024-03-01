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
	public static func xrd(balance: ResourceAmount) -> Self {
		.init(
			address: try! .init(validatingAddress: "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd"), // FIXME: REMOVE
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
