// MARK: - VerifyDapp.View
public extension VerifyDapp {
	struct View: SwiftUI.View {
		let store: StoreOf<VerifyDapp>

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: identity, send: FeatureAction.view) { viewStore in
				ScrollView {
					VStack(spacing: .medium1) {
						DappHeader(
							thumbnail: viewStore.dAppMetadata.thumbnail,
							title: "Verifying dApp",
							subtitle: "\(viewStore.dAppMetadata.name) is requesting verification"
						)

						Text("**\(viewStore.dAppMetadata.name)** wants to make requests to your Radix Wallet. Click Continue to verify the identity of this dApp and proceed with the request.")
							.textStyle(.body1HighImportance)
					}
					.padding(.medium1)
				}
				.footer {
					Button(L10n.DAppRequest.Login.continue) {
						viewStore.send(.continueTapped)
					}
					.buttonStyle(.primaryRectangular)
				}
			}
			.withNavigationBar {
				store.send(.view(.closeTapped))
			}
		}
	}
}
