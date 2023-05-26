import Prelude
import SharedModels
import SwiftUI

// MARK: - SmallAccountCard
public struct SmallAccountCard<Accessory: View>: View {
	let name: String
	let identifiable: LedgerIdentifiable
	let gradient: Gradient
	let height: CGFloat
	let accessory: Accessory

	public init(
		_ name: String,
		identifiable: LedgerIdentifiable,
		gradient: Gradient,
		height: CGFloat = .standardButtonHeight,
		@ViewBuilder accessory: () -> Accessory = { EmptyView() }
	) {
		self.name = name
		self.identifiable = identifiable
		self.gradient = gradient
		self.height = height
		self.accessory = accessory()
	}
}

extension SmallAccountCard where Accessory == EmptyView {
	public init(account: Profile.Network.AccountForDisplay) {
		self.init(
			account.label.rawValue,
			identifiable: .address(.account(account.address)),
			gradient: .init(account.appearanceID),
			height: .guaranteeAccountLabelHeight
		)
	}

	public init(account: Profile.Network.Account) {
		self.init(
			account.displayName.rawValue,
			identifiable: .address(.account(account.address)),
			gradient: .init(account.appearanceID),
			height: .guaranteeAccountLabelHeight
		)
	}
}

extension SmallAccountCard {
	public var body: some View {
		HStack(spacing: 0) {
			Text(name)
				.foregroundColor(.app.white)
				.textStyle(.body1Header)

			Spacer(minLength: 0)

			AddressView(identifiable)
				.foregroundColor(.app.whiteTransparent)
				.textStyle(.body2HighImportance)
			accessory
		}
		.padding(.horizontal, .medium3)
		.frame(height: height)
		.background {
			LinearGradient(gradient: gradient, startPoint: .leading, endPoint: .trailing)
		}
	}
}
