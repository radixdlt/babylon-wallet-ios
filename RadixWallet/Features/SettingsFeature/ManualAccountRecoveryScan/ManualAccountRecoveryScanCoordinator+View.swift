import ComposableArchitecture
import SwiftUI

// MARK: - ManualAccountRecoveryScanCoordinator.View
extension ManualAccountRecoveryScanCoordinator {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

extension ManualAccountRecoveryScanCoordinator.View {
	public var body: some View {
		NavigationStackStore(
			store.scope(state: \.path, action: { .child(.path($0)) })
		) {
			Color.orange
		} destination: {
			PathView(store: $0)
		}
	}
}

private extension ManualAccountRecoveryScanCoordinator.View {
	struct RootView: View {
		let store: StoreOf<ManualAccountRecoveryScanCoordinator.Path>

		var body: some View {
			SwitchStore(store) { state in
				switch state {
				case .chooseSeedPhrase:
					CaseLet(
						/ManualAccountRecoveryScanCoordinator.Path.State.chooseSeedPhrase,
						action: ManualAccountRecoveryScanCoordinator.Path.Action.chooseSeedPhrase,
						then: { ManualAccountRecoveryScanCoordinator.ChooseSeedPhrase.View(store: $0) }
					)
				case .chooseLedger:
					CaseLet(
						/ManualAccountRecoveryScanCoordinator.Path.State.chooseLedger,
						action: ManualAccountRecoveryScanCoordinator.Path.Action.chooseLedger,
						then: { ManualAccountRecoveryScanCoordinator.ChooseLedger.View(store: $0) }
					)
				}
			}
		}
	}

	struct PathView: View {
		let store: StoreOf<ManualAccountRecoveryScanCoordinator.Path>

		var body: some View {
			SwitchStore(store) { state in
				switch state {
				case .chooseSeedPhrase:
					CaseLet(
						/ManualAccountRecoveryScanCoordinator.Path.State.chooseSeedPhrase,
						action: ManualAccountRecoveryScanCoordinator.Path.Action.chooseSeedPhrase,
						then: { ManualAccountRecoveryScanCoordinator.ChooseSeedPhrase.View(store: $0) }
					)
				case .chooseLedger:
					CaseLet(
						/ManualAccountRecoveryScanCoordinator.Path.State.chooseLedger,
						action: ManualAccountRecoveryScanCoordinator.Path.Action.chooseLedger,
						then: { ManualAccountRecoveryScanCoordinator.ChooseLedger.View(store: $0) }
					)
				}
			}
		}
	}
}

// MARK: - ManualAccountRecoveryScanCoordinator.ChooseLedger.View
extension ManualAccountRecoveryScanCoordinator.ChooseLedger {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			Color.blue
		}
	}
}

// MARK: - ManualAccountRecoveryScanCoordinator.ChooseSeedPhrase.View
extension ManualAccountRecoveryScanCoordinator.ChooseSeedPhrase {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			Color.red
		}
	}
}
