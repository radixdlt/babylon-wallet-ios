// MARK: - SmallAccountCard
public struct SmallAccountCard<Accessory: View>: View {
	let name: String?
	let identifiable: LedgerIdentifiable
	let gradient: Gradient
	let verticalPadding: CGFloat
	let accessory: Accessory

	public init(
		_ name: String? = nil,
		identifiable: LedgerIdentifiable,
		gradient: Gradient,
		verticalPadding: CGFloat = .medium3,
		@ViewBuilder accessory: () -> Accessory = { EmptyView() }
	) {
		self.name = name
		self.identifiable = identifiable
		self.gradient = gradient
		self.verticalPadding = verticalPadding
		self.accessory = accessory()
	}

	public var body: some View {
		HStack(spacing: 0) {
			if let name {
				Text(name)
					.foregroundColor(.app.white)
					.textStyle(.body1Header)
			}

			Spacer(minLength: 0)

			AddressView(identifiable)
				.foregroundColor(.app.whiteTransparent)
				.textStyle(.body2HighImportance)

			accessory
		}
		.padding(.vertical, verticalPadding)
		.padding(.horizontal, .medium3)
		.background {
			LinearGradient(gradient: gradient, startPoint: .leading, endPoint: .trailing)
		}
	}
}

extension SmallAccountCard where Accessory == EmptyView {
	public init(account: Profile.Network.Account) {
		self.init(
			account.displayName.rawValue,
			identifiable: .address(of: account),
			gradient: .init(account.appearanceID),
			verticalPadding: .small1 - 1
		)
	}
}
