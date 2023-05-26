import FeaturePrelude

extension DisplayMnemonics.State {
	var viewState: DisplayMnemonics.ViewState {
		.init(deviceFactorSources: $deviceFactorSources)
	}
}

// MARK: - DisplayMnemonics.View
extension DisplayMnemonics {
	public struct ViewState: Equatable {
		// TODO: declare some properties
		let deviceFactorSources: Loadable<NonEmpty<IdentifiedArrayOf<HDOnDeviceFactorSource>>>
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<DisplayMnemonics>

		public init(store: StoreOf<DisplayMnemonics>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					deviceFactorSourcesListView(viewStore: viewStore)
				}
				.onFirstTask { @MainActor in
					viewStore.send(.onFirstTask)
				}
			}
		}

		@ViewBuilder
		private func deviceFactorSourcesListView(viewStore: ViewStoreOf<DisplayMnemonics>) -> some SwiftUI.View {
			switch viewStore.deviceFactorSources {
			case .idle, .loading:
				EmptyView()
			case let .failure(error):
				Text("Failed to load factor sources: \(String(describing: error))")
			case let .success(deviceFactorSources):
				ForEach(deviceFactorSources) { deviceFactorSource in
					DeviceFactorSourceRowView(deviceFactorSource: deviceFactorSource)
				}
			}
		}
	}
}

// MARK: - DeviceFactorSourceRowView
struct DeviceFactorSourceRowView: SwiftUI.View {
	let deviceFactorSource: HDOnDeviceFactorSource
	private var olympiaLabelOrEmpty: String {
		guard deviceFactorSource.supportsOlympia else { return "" }
		return " (Olympia)"
	}

	var body: some SwiftUI.View {
		Text("Mnemonic: added \(deviceFactorSource.addedOn.ISO8601Format(.iso8601Date(timeZone: .current)))\(olympiaLabelOrEmpty)")
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - DisplayMnemonics_Preview
struct DisplayMnemonics_Preview: PreviewProvider {
	static var previews: some View {
		DisplayMnemonics.View(
			store: .init(
				initialState: .previewValue,
				reducer: DisplayMnemonics()
			)
		)
	}
}

extension DisplayMnemonics.State {
	public static let previewValue = Self()
}
#endif
