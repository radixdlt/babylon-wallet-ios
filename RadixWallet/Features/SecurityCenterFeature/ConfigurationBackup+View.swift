import ComposableArchitecture
import SwiftUI

// MARK: - ConfigurationBackup.View
extension ConfigurationBackup {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ConfigurationBackup>

		public init(store: StoreOf<ConfigurationBackup>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { _ in
				ScrollView {
					VStack(spacing: .zero) {
						Text(L10n.SecurityCenter.subtitle)
							.foregroundStyle(.app.gray1)
							.textStyle(.body1Regular)
							.padding(.bottom, .medium1)

						GoodStateView()
					}
					.padding(.top, .small2)
					.padding(.horizontal, .medium2)
				}
			}
			.navigationBarTitleDisplayMode(.large)
			.navigationTitle(L10n.SecurityCenter.title)
		}
	}
}

// MARK: - ConfigurationBackup.GoodStateView
extension ConfigurationBackup {
	struct GoodStateView: SwiftUI.View {
		var body: some SwiftUI.View {
			HStack(spacing: 0) {
				Image(.security)
					.padding(.trailing, .small2)

				Text(L10n.SecurityCenter.Status.recoverable)
					.textStyle(.body1Header)

				Spacer(minLength: .zero)
			}
			.foregroundStyle(.white)
			.padding(.vertical, .small2)
			.padding(.horizontal, .medium2)
			.background(.app.green1)
			.roundedCorners(radius: .small1)
		}
	}
}
