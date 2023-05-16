import FeaturePrelude

// MARK: - ReceivingAccount.View
extension ReceivingAccount {
	public typealias ViewState = State

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ReceivingAccount>
		let focused: FocusState<TransferFocusedField?>.Binding

		public init(store: StoreOf<ReceivingAccount>, focused: FocusState<TransferFocusedField?>.Binding) {
			self.store = store
			self.focused = focused
		}
	}
}

extension ReceivingAccount.View {
	public var body: some View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
			VStack(alignment: .leading, spacing: 0) {
				Group {
					if let account = viewStore.account {
						SmallAccountCard(account.name, identifiable: account.identifer, gradient: account.gradient) {
							FixedSpacer(width: .small1)
							Button("", asset: AssetResource.close) {
								viewStore.send(.removeTapped)
							}
							.foregroundColor(.app.white)
						}
					} else {
						HStack {
							Button("Choose Account") {
								viewStore.send(.chooseAccountTapped)
							}
							.textStyle(.body1Header)
							Spacer()
							if viewStore.canBeRemovedWhenEmpty {
								Button("", asset: AssetResource.close) {
									viewStore.send(.removeTapped)
								}
							}
						}
						.frame(height: .standardButtonHeight)
						.padding(.horizontal, .medium3)
						.foregroundColor(.app.gray2)
					}
				}
				.topRoundedCorners(strokeColor: .borderColor)

				VStack {
					ForEachStore(
						store.scope(state: \.assets, action: { .child(.row(id: $0, child: $1)) }),
						content: { FungibleResourceAsset.View(store: $0, focused: focused) }
					)

					Button("Add Assets") {
						viewStore.send(.addAssetTapped)
					}
					.padding(.small1)
					.frame(height: .standardButtonHeight)
					.foregroundColor(.app.gray2)
					.textStyle(.body1StandaloneLink)
				}
				.frame(maxWidth: .infinity)
				.background(Color.containerContentBackground)
				.bottomRoundedCorners(strokeColor: .borderColor)
			}
			.sheet(
				store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
				state: /ReceivingAccount.Destinations.State.chooseAccount,
				action: ReceivingAccount.Destinations.Action.chooseAccount,
				content: { ChooseAccount.View(store: $0) }
			)
			.sheet(
				store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
				state: /ReceivingAccount.Destinations.State.addAsset,
				action: ReceivingAccount.Destinations.Action.addAsset,
				content: { AddAsset.View(store: $0) }
			)
		}
	}

	private func assetRow() -> some View {
		HStack {
			HStack {
				Image(asset: AssetResource.xrd)
					.resizable()
					.frame(.smallest)
				Text("XRD")
					.foregroundColor(.app.gray1)
					.textStyle(.body2HighImportance)

				Spacer()

				TextField("0.00", text: .constant("0.00"))
					.keyboardType(.numbersAndPunctuation)
					.lineLimit(1)
					.multilineTextAlignment(.trailing)
					.foregroundColor(.app.gray1)
					.textStyle(.sectionHeader)
			}
			.padding(.medium3)
			.background(.app.white)
			.cornerRadius(.small2)

			Spacer()
			Button("", asset: AssetResource.close) {
				// viewStore.send(.)
			}
		}
		.padding(.small1)
	}
}
