import Foundation

// MARK: - InfoLinkSheet
public struct InfoLinkSheet: FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public let id = UUID()
		public let image: ImageAsset?
		public let text: String
	}

	public enum ViewAction: Equatable, Sendable {
		case infoLinkTapped(OverlayWindowClient.GlossaryItem)
	}

	@Dependency(\.overlayWindowClient) var overlayWindowClient

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .infoLinkTapped(infoLink):
			overlayWindowClient.showInfoLink(infoLink)
			return .none
		}
	}
}
