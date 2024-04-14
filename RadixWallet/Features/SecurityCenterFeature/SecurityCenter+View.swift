import ComposableArchitecture
import SwiftUI

extension SecurityCenter {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SecurityCenter>

		public init(store: StoreOf<SecurityCenter>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			EmptyView()
				.navigationTitle("Security")
		}
	}
}
