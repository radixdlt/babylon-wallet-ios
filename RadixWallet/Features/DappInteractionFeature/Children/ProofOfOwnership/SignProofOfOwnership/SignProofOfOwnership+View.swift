import SwiftUI

extension SignProofOfOwnership {
	typealias View = Never

	struct ViewModifier: SwiftUI.ViewModifier {
		let store: StoreOf<SignProofOfOwnership>

		func body(content: Content) -> some SwiftUI.View {
			content
				.destinations(with: store)
		}
	}
}

extension View {
	func signProofOfOwnership(store: StoreOf<SignProofOfOwnership>) -> some View {
		self.modifier(SignProofOfOwnership.ViewModifier(store: store))
	}
}

private extension StoreOf<SignProofOfOwnership> {
	var destination: PresentationStoreOf<SignProofOfOwnership.Destination> {
		func scopeState(state: State) -> PresentationState<SignProofOfOwnership.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<SignProofOfOwnership>) -> some View {
		let destinationStore = store.destination
		return sheet(store: destinationStore.scope(state: \.signing, action: \.signing)) {
			Signing.View(store: $0)
		}
	}
}
