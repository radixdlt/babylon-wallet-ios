import FeaturePrelude
import SwiftUI

// MARK: - Startup.View
extension Startup {
	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<Startup>
		public init(store: StoreOf<Startup>) {
			self.store = store
		}
	}
}

extension Startup.View {
	public var body: some View {
		ForceFullScreen {
			NavigationStack {
				WithViewStore(store, observe: { $0 }) { viewStore in
					// TODO: This is stubbed based on Figma design, to be updated properly based on the final Onboarding design
					VStack(spacing: .medium1) {
						Text("A World of Possibilities")
							.foregroundColor(.app.gray1)
							.textStyle(.sheetTitle)
							.multilineTextAlignment(.center)
						Text("Let's get started")
							.foregroundColor(.app.gray2)
							.textStyle(.secondaryHeader)

						Spacer()

						Button("I'am new Radix Wallet user") {
							viewStore.send(.view(.selectedNewWalletUser))
						}.buttonStyle(.primaryRectangular)

						Button("Restore Wallet from backup") {
							viewStore.send(.view(.selectedRestoreFromBackup))
						}
						.buttonStyle(.primaryText())
					}
					.padding([.horizontal, .bottom], .medium1)
				}
				.navigationDestination(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /Startup.Destinations.State.restoreFromBackup,
					action: Startup.Destinations.Action.restoreFromBackup,
					destination: {
						RestoreFromBackup.View(store: $0)
					}
				)
			}
		}
	}
}
