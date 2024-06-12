// MARK: - VerifyDapp.View
public extension VerifyDapp {
	struct View: SwiftUI.View {
		let store: StoreOf<VerifyDapp>

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: identity, send: FeatureAction.view) { viewStore in
				if viewStore.autoContinueEnabled {
					automatic(metadata: viewStore.dAppMetadata)
				} else {
					manual(
						metadata: viewStore.dAppMetadata,
						autoContinueEnabled: viewStore.binding(get: \.autoContinueSelection, send: { .autoContinueSelection($0) })
					)
				}
			}
			.task { @MainActor in
				await store.send(.view(.task)).finish()
			}
		}

		private func automatic(metadata: DappMetadata) -> some SwiftUI.View {
			VStack(spacing: .huge2) {
				Spacer()
				DappHeader(thumbnail: metadata.thumbnail, title: "Connecting to \(metadata.name)", subtitle: nil)

				LoadingView(lineWidth: .small3, stroke: .app.gray2)
					.frame(width: .huge1, height: .huge1)
				Spacer()
			}
		}

		private func manual(metadata: DappMetadata, autoContinueEnabled: Binding<Bool>) -> some SwiftUI.View {
			VStack(spacing: .medium1) {
				DappHeader(
					thumbnail: metadata.thumbnail,
					title: "Connecting to \(metadata.name)",
					subtitle: "You're connecting to \(metadata.name) for the first time"
				)
				.fixedSize(horizontal: false, vertical: true)

				Text("For this first connection, we’re going to run some quick automatic checks to verify the dApp.")
					.textStyle(.body1HighImportance)
					.multilineTextAlignment(.center)

				Spacer()

				ToggleView(
					title: "Never show this screen again",
					subtitle: "Run all future verification checks automatically",
					isOn: autoContinueEnabled
				)
			}
			.padding(.medium1)
			.footer {
				Button(L10n.DAppRequest.Login.continue) {
					store.send(.view(.continueTapped))
				}
				.buttonStyle(.primaryRectangular)
			}
		}
	}
}
