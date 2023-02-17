import FeaturePrelude

extension Header.State {
	var viewState: Header.ViewState {
		.init(hasNotification: hasNotification)
	}
}

extension Header {
	struct ViewState: Equatable {
		var hasNotification: Bool
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
				VStack(alignment: .leading) {
					TitleView(
						shouldShowNotification: viewStore.state.hasNotification,
						settingsButtonAction: {
							viewStore.send(.settingsButtonTapped)
						}
					)
					subtitleView
				}
			}
		}

		fileprivate var subtitleView: some SwiftUI.View {
			HStack(spacing: .large1) {
				Text(L10n.Home.Header.subtitle)
					.foregroundColor(.app.gray2)
					.textStyle(.body1HighImportance)
				Spacer(minLength: .large1)
			}
		}
	}

	private struct TitleView: SwiftUI.View {
		var shouldShowNotification: Bool
		let settingsButtonAction: () -> Void

		var body: some SwiftUI.View {
			HStack {
				Text(L10n.Home.Header.title)
					.foregroundColor(.app.gray1)
					.textStyle(.sheetTitle)
				Spacer()
				SettingsButton(
					shouldShowNotification: shouldShowNotification,
					action: settingsButtonAction
				)
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

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct Header_Preview: PreviewProvider {
	static var previews: some View {
		Header.View(
			store: .init(
				initialState: .init(),
				reducer: Header()
			)
		)
	}
}
#endif
