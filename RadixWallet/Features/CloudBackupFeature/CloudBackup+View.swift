import ComposableArchitecture
import SwiftUI

extension CloudBackup {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CloudBackup>

		public init(store: StoreOf<CloudBackup>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			EmptyView()
		}
	}
}
