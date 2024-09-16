// MARK: - UpdateP2PLinkName
@Reducer
public struct UpdateP2PLinkName: FeatureReducer, Sendable {
	@ObservableState
	public struct State: Hashable, Sendable {
		var link: P2PLink
		var linkName: String
		var sanitizedName: NonEmptyString?
		var textFieldFocused: Bool = true

		init(link: P2PLink) {
			self.link = link
			self.linkName = link.displayName
			self.sanitizedName = NonEmptyString(maybeString: link.displayName)
		}
	}

	public typealias Action = FeatureAction<Self>

	@CasePathable
	public enum ViewAction: Equatable, Sendable {
		case closeButtonTapped
		case linkNameChanged(String)
		case updateTapped(NonEmptyString)
		case focusChanged(Bool)
	}

	public enum DelegateAction: Equatable, Sendable {
		case linkNameUpdated(P2PLink)
	}

	@Dependency(\.p2pLinksClient) var p2pLinksClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.dismiss) var dismiss

	public var body: some ReducerOf<Self> {
		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return .run { _ in
				await dismiss()
			}

		case let .linkNameChanged(name):
			state.linkName = name
			state.sanitizedName = NonEmpty(rawValue: name.trimmingNewlines())
			return .none

		case let .updateTapped(newLabel):
			state.link.displayName = newLabel.rawValue
			return .run { [link = state.link] send in
				do {
					try await p2pLinksClient.updateP2PLink(link)
					overlayWindowClient.scheduleHUD(.init(text: L10n.LinkedConnectors.RenameConnector.successHud))
					await send(.delegate(.linkNameUpdated(link)))
				} catch {
					errorQueue.schedule(error)
				}
			}

		case let .focusChanged(value):
			state.textFieldFocused = value
			return .none
		}
	}
}
