import Common
import ComposableArchitecture
import SwiftUI

// MARK: - Home.Header.View
public extension Home.Header {
	struct View: SwiftUI.View {
		let store: Store<State, Action>
	}
}

public extension Home.Header.View {
	var body: some View {
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

private extension Home.Header.View {
	var subtitleView: some SwiftUI.View {
		HStack {
			Text(L10n.Home.Header.subtitle)
				.foregroundColor(.app.gray2)
				.textStyle(.body1Regular)
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
				.foregroundColor(.app.buttonTextBlack)
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
			// TODO: use swiftgen for assets
			Button(action: action) {
				Image(asset: Asset.homeHeaderSettings)
			}

			if shouldShowNotification {
				Circle()
					.foregroundColor(.app.notification)
					.frame(width: 5, height: 5)
			}
		}
	}
}

// MARK: - Header_Preview
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
