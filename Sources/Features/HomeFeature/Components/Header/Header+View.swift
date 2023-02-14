import FeaturePrelude

// MARK: - Home.Header.View
extension Home.Header {
	@MainActor
	public struct View: SwiftUI.View {
		let store: Store<State, Action>
	}
}

extension Home.Header.View {
	public var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
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
}

// MARK: - Home.Header.View.ViewState
extension Home.Header.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		var hasNotification: Bool

		init(state: Home.Header.State) {
			hasNotification = state.hasNotification
		}
	}
}

extension Home.Header.View {
	fileprivate var subtitleView: some SwiftUI.View {
		HStack(spacing: .large1) {
			Text(L10n.Home.Header.subtitle)
				.foregroundColor(.app.gray2)
				.textStyle(.body1HighImportance)
			Spacer(minLength: .large1)
		}
	}
}

// MARK: - TitleView
private struct TitleView: View {
	var shouldShowNotification: Bool
	let settingsButtonAction: () -> Void

	public var body: some View {
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

// MARK: - SettingsButton
private struct SettingsButton: View {
	let shouldShowNotification: Bool
	let action: () -> Void

	public var body: some View {
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

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct Header_Preview: PreviewProvider {
	static var previews: some View {
		Home.Header.View(
			store: .init(
				initialState: .init(),
				reducer: Home.Header()
			)
		)
	}
}
#endif
