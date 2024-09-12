// MARK: - UpdateP2PLinkName
public struct UpdateP2PLinkName: FeatureReducer, Sendable {
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

	public enum ViewAction: Equatable, Sendable {
		case linkNameChanged(String)
		case updateTapped(NonEmptyString)
		case focusChanged(Bool)
	}

	public enum DelegateAction: Equatable, Sendable {
		case linkNameUpdated(P2PLink)
	}

	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .linkNameChanged(name):
			state.linkName = name
			state.sanitizedName = NonEmpty(rawValue: name.trimmingNewlines())
			return .none

		case let .updateTapped(newLabel):
			state.link.displayName = newLabel.rawValue
			return .run { [link = state.link] send in
				do {
					try await radixConnectClient.updateP2PLink(link)
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
