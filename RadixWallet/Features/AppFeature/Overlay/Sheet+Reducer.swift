import Foundation

public struct Sheet: FeatureReducer {
	public typealias State = OverlayWindowClient.Item.SheetState

	public enum ViewAction: Equatable, Sendable {
		case infoLinkTapped(OverlayWindowClient.GlossaryItem)
		case closeButtonTapped
	}

	public enum DelegateAction: Equatable, Sendable {
		case dismiss
	}

	@Dependency(\.overlayWindowClient) var overlayWindowClient

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .infoLinkTapped(infoLink):
			overlayWindowClient.showInfoLink(infoLink)
			return .none
		case .closeButtonTapped:
			return .run { send in
				await send(.delegate(.dismiss))
			}
		}
	}
}
