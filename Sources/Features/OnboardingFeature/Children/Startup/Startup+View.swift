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
			WithViewStore(store, observe: { $0 }) { viewStore in
				VStack(spacing: .medium1) {
					Button("Create First Account") {
						viewStore.send(.view(.selectedCreateFirstAccount))
					}.buttonStyle(.primaryRectangular)

					Button("Load backup") {
						viewStore.send(.view(.selectedLoadBackup))
					}.buttonStyle(.primaryRectangular)

					Button("Import Profile") {
						viewStore.send(.view(.selectedImportProfile))
					}.buttonStyle(.primaryRectangular)
				}.padding([.horizontal, .bottom], .medium1)
			}
		}
	}
}
