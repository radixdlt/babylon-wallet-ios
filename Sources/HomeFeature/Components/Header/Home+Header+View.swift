import Common
import SwiftUI

public extension Home.Header {
	struct View: SwiftUI.View {
		let action: () -> Void
		let shouldShowNotification: Bool

		public var body: some SwiftUI.View {
			Home.Header.TitleView(action: action,
			                      shouldShowNotification: shouldShowNotification)
				.padding(EdgeInsets(top: 57, leading: 31, bottom: 0, trailing: 31))
				//            Home.Header.subtitle
				.padding(EdgeInsets(top: 0, leading: 29, bottom: 0, trailing: 29))
		}
	}
}

extension Home.Header {
	var subtitleView: some SwiftUI.View {
		GeometryReader { proxy in
			Text(L10n.Home.Wallet.subtitle)
				.frame(width: proxy.size.width * 0.7)
				.font(.app.body)
				.foregroundColor(.app.secondary)
		}
	}

	struct TitleView: SwiftUI.View {
		let action: () -> Void
		var shouldShowNotification: Bool

		public var body: some SwiftUI.View {
			HStack {
				Text(L10n.Home.Wallet.title)
					.font(.app.title)
				Spacer()
				SettingsButton(action: action, shouldShowNotification: shouldShowNotification)
			}
		}
	}

	struct SettingsButton: SwiftUI.View {
		let action: () -> Void
		var shouldShowNotification: Bool

		public var body: some SwiftUI.View {
			ZStack(alignment: .topTrailing) {
				Button(action: {
					action()
				}, label: {
					Image("home-settings")
				})

				if shouldShowNotification {
					Circle()
						.foregroundColor(.app.notification)
						.frame(width: 5, height: 5)
				}
			}
		}
	}
}
