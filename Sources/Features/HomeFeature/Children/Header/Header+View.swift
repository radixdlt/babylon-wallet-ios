import FeaturePrelude

extension Header.State {
	var viewState: Header.ViewState {
		.init(hasNotification: hasNotification)
	}
}

extension Header {
	struct ViewState: Equatable {
		let hasNotification: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<Header>

		init(store: StoreOf<Header>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: \.viewState,
				send: { .view($0) }
			) { viewStore in
				ZStack {
					Text(L10n.Home.Header.subtitle)
						.foregroundColor(.app.gray2)
						.textStyle(.body1HighImportance)
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(.leading, .large2)
						.padding(.trailing, 100)
				}
				.padding(.top, .small3)
				.navigationTitle(L10n.Home.Header.title)
				.navigationBarTitleColor(.app.gray1)
				.navigationBarTitleDisplayMode(.large)
				.navigationBarTitleFont(.app.sheetTitle, for: .large)
				.navigationBarTitleFont(.app.secondaryHeader, for: .inline)
				.introspectNavigationController { controller in
					controller.navigationBar.layoutMargins.left = .large2
					controller.navigationBar.layoutMargins.right = .large2
				}
				.toolbar {
					ToolbarItem(placement: .navigationBarTrailing) {
						SettingsButton(
							shouldShowNotification: viewStore.hasNotification,
							action: { viewStore.send(.settingsButtonTapped) }
						)
					}
				}
			}
		}

		private struct SettingsButton: SwiftUI.View {
			let shouldShowNotification: Bool
			let action: () -> Void

			var body: some SwiftUI.View {
				ZStack(alignment: .topTrailing) {
					Button(action: action) {
						Image(asset: AssetResource.homeHeaderSettings)
					}
					.frame(.small)

					if shouldShowNotification {
						Circle()
							.foregroundColor(.app.notification)
							.frame(width: 5, height: 5)
					}
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct Header_Preview: PreviewProvider {
	static var previews: some View {
		NavigationStack {
			ScrollView {
				Header.View(
					store: .init(
						initialState: .previewValue,
						reducer: Header()
					)
				)
			}
		}
	}
}

extension Header.State {
	static let previewValue = Self()
}
#endif
