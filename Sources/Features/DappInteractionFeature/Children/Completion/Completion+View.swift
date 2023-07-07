import FeaturePrelude

extension DappMetadata {
	var name: String {
		switch self {
		case let .ledger(ledger):
			return ledger.name?.rawValue ?? L10n.DAppRequest.Metadata.unknownName
		case .request:
			return L10n.DAppRequest.Metadata.unknownName
		case .wallet:
			return "Radix Wallet"
		}
	}
}

// MARK: - Completion.View
extension Completion {
	struct ViewState: Equatable {
		let title: String
		let subtitle: String

		init(state: Completion.State) {
			title = L10n.DAppRequest.Completion.title
			subtitle = L10n.DAppRequest.Completion.subtitle(state.dappMetadata.name)
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<Completion>

		var body: some SwiftUI.View {
			WithViewStore(store, observe: ViewState.init, send: { .view($0) }) { viewStore in
				WithNavigationBar {
					viewStore.send(.closeButtonTapped)
				} content: {
					VStack(spacing: .medium2) {
						Image(asset: AssetResource.successCheckmark)

						Text(viewStore.title)
							.foregroundColor(.app.gray1)
							.textStyle(.sheetTitle)

						Text(viewStore.subtitle)
							.foregroundColor(.app.gray1)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)
					}
					.padding(.horizontal, .medium2)
					.padding(.bottom, .medium3)
				}
			}
			.presentationDragIndicator(.visible)
			.presentationDetents([.height(.smallDetent)])
			#if os(iOS)
				.presentationBackground(.blur)
			#endif
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - Completion_Preview
struct Completion_Preview: PreviewProvider {
	static var previews: some SwiftUI.View {
		WithState(initialValue: false) { $isPresented in
			ZStack {
				Color.red
				Button("Present") { isPresented = true }
			}
			.sheet(isPresented: $isPresented) {
				Completion.View(
					store: .init(
						initialState: .previewValue,
						reducer: Completion()
					)
				)
			}
			.task {
				try? await Task.sleep(for: .seconds(2))
				isPresented = true
			}
		}
	}
}

extension Completion.State {
	static let previewValue: Self = .init(dappMetadata: .previewValue)
}
#endif
