import ComposableArchitecture
import Sargon

// MARK: - SignalingServerDetails
@Reducer
struct SignalingServerDetails: FeatureReducer {
	@ObservableState
	struct State: Hashable {
		enum Mode: Hashable {
			case create
			case edit(id: String)
		}

		enum Field: String, Hashable {
			case name
			case signalingServer
			case turnUsername
			case turnCredential
		}

		struct URLFieldState: Hashable, Identifiable {
			let id: UUID
			var value: String

			init(id: UUID = UUID(), value: String = "") {
				self.id = id
				self.value = value
			}
		}

		var mode: Mode
		var originalProfile: P2PTransportProfile?
		var isCurrent = false
		var focusedField: Field?
		var name = ""
		var signalingServer = ""
		var stunURLs: IdentifiedArrayOf<URLFieldState> = []
		var turnURLs: IdentifiedArrayOf<URLFieldState> = []
		var turnUsername = ""
		var turnCredential = ""
		var saveButtonState: ControlState = .disabled
		var errorText: String?

		@Presents
		var destination: Destination.State?

		static let create = Self(mode: .create)
		static func edit(id: String) -> Self {
			Self(mode: .edit(id: id))
		}

		var isEditMode: Bool {
			if case .edit = mode { true } else { false }
		}

		var canAddStunURL: Bool {
			stunURLs.allSatisfy { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
		}

		var canAddTurnURL: Bool {
			turnURLs.allSatisfy { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
		}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Equatable {
		case task
		case textFieldFocused(State.Field?)
		case nameChanged(String)
		case signalingServerChanged(String)
		case stunURLChanged(UUID, String)
		case addStunURLTapped
		case deleteStunURLTapped(UUID)
		case turnURLChanged(UUID, String)
		case addTurnURLTapped
		case deleteTurnURLTapped(UUID)
		case turnUsernameChanged(String)
		case turnCredentialChanged(String)
		case saveButtonTapped
		case changeCurrentTapped
		case deleteTapped
	}

	enum InternalAction: Equatable {
		case focusTextField(State.Field?)
		case profileLoaded(TaskResult<LoadedProfile>)
		case duplicateURLFound
		case saveResult(TaskResult<Bool>)
		case changeCurrentResult(TaskResult<Bool>)
		case deleteResult(TaskResult<Bool>)
	}

	enum DelegateAction: Equatable {
		case updated
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Hashable {
			case deleteAlert(AlertState<Action.DeleteAlert>)
		}

		@CasePathable
		enum Action: Equatable {
			case deleteAlert(DeleteAlert)

			enum DeleteAlert: Hashable {
				case confirmTapped
				case cancelTapped
			}
		}

		var body: some ReducerOf<Self> {
			EmptyReducer()
		}
	}

	struct LoadedProfile: Hashable {
		let profile: P2PTransportProfile
		let isCurrent: Bool
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.p2pTransportProfilesClient) var p2pTransportProfilesClient

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: \.destination) {
				Destination()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			switch state.mode {
			case .create:
				refreshSaveButtonState(state: &state)
				return .send(.internal(.focusTextField(.name)))

			case let .edit(id):
				return .run { send in
					let result = await TaskResult {
						let profiles = try await p2pTransportProfilesClient.getProfiles()
						guard let profile = profiles.all.first(where: { $0.signalingServer == id }) else {
							throw MissingProfile()
						}
						return LoadedProfile(profile: profile, isCurrent: profiles.current.signalingServer == profile.signalingServer)
					}
					await send(.internal(.profileLoaded(result)))
				}
			}

		case let .textFieldFocused(focus):
			return .send(.internal(.focusTextField(focus)))

		case let .nameChanged(value):
			state.name = value
			refreshSaveButtonState(state: &state)
			return .none

		case let .signalingServerChanged(value):
			state.signalingServer = value
			refreshSaveButtonState(state: &state)
			return .none

		case let .stunURLChanged(id, value):
			state.stunURLs[id: id]?.value = value
			refreshSaveButtonState(state: &state)
			return .none

		case .addStunURLTapped:
			guard state.canAddStunURL else { return .none }
			state.stunURLs.append(.init())
			refreshSaveButtonState(state: &state)
			return .none

		case let .deleteStunURLTapped(id):
			state.stunURLs.remove(id: id)
			refreshSaveButtonState(state: &state)
			return .none

		case let .turnURLChanged(id, value):
			state.turnURLs[id: id]?.value = value
			refreshSaveButtonState(state: &state)
			return .none

		case .addTurnURLTapped:
			guard state.canAddTurnURL else { return .none }
			state.turnURLs.append(.init())
			refreshSaveButtonState(state: &state)
			return .none

		case let .deleteTurnURLTapped(id):
			state.turnURLs.remove(id: id)
			refreshSaveButtonState(state: &state)
			return .none

		case let .turnUsernameChanged(value):
			state.turnUsername = value
			refreshSaveButtonState(state: &state)
			return .none

		case let .turnCredentialChanged(value):
			state.turnCredential = value
			refreshSaveButtonState(state: &state)
			return .none

		case .saveButtonTapped:
			guard let profile = makeProfile(from: state) else {
				return .none
			}

			state.errorText = nil
			state.saveButtonState = .loading(.local)
			let isEditMode = state.isEditMode
			return .run { send in
				if !isEditMode, try await p2pTransportProfilesClient.hasProfileWithSignalingServerURL(profile.signalingServer) {
					await send(.internal(.duplicateURLFound))
					return
				}

				let result = await TaskResult {
					isEditMode ? try await p2pTransportProfilesClient.updateProfile(profile) : try await p2pTransportProfilesClient.addProfile(profile)
				}
				await send(.internal(.saveResult(result)))
			}

		case .changeCurrentTapped:
			guard
				let originalProfile = state.originalProfile,
				!state.isCurrent
			else {
				return .none
			}

			return .run { send in
				let result = await TaskResult {
					try await p2pTransportProfilesClient.changeProfile(originalProfile)
				}
				await send(.internal(.changeCurrentResult(result)))
			}

		case .deleteTapped:
			state.destination = .deleteAlert(.deleteConfirmation)
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .focusTextField(focus):
			state.focusedField = focus
			return .none

		case let .profileLoaded(.success(loadedProfile)):
			populate(state: &state, with: loadedProfile)
			refreshSaveButtonState(state: &state)
			return .none

		case let .profileLoaded(.failure(error)):
			errorQueue.schedule(error)
			state.errorText = "Failed to load signaling server."
			refreshSaveButtonState(state: &state)
			return .none

		case .duplicateURLFound:
			state.errorText = "A signaling server with this URL already exists."
			refreshSaveButtonState(state: &state)
			return .none

		case let .saveResult(.success(success)):
			guard success else {
				state.errorText = state.isEditMode ? "Failed to update signaling server." : "Failed to add signaling server."
				refreshSaveButtonState(state: &state)
				return .none
			}
			return .concatenate(
				.send(.delegate(.updated)),
				.run { _ in
					await dismiss()
				}
			)

		case let .saveResult(.failure(error)):
			errorQueue.schedule(error)
			state.errorText = state.isEditMode ? "Failed to update signaling server." : "Failed to add signaling server."
			refreshSaveButtonState(state: &state)
			return .none

		case let .changeCurrentResult(.success(success)):
			guard success else {
				state.errorText = "Failed to change current signaling server."
				return .none
			}
			return .concatenate(
				.send(.delegate(.updated)),
				.run { _ in
					await dismiss()
				}
			)

		case let .changeCurrentResult(.failure(error)):
			errorQueue.schedule(error)
			state.errorText = "Failed to change current signaling server."
			return .none

		case let .deleteResult(.success(success)):
			guard success else {
				state.errorText = "Failed to delete signaling server."
				return .none
			}
			return .concatenate(
				.send(.delegate(.updated)),
				.run { _ in
					await dismiss()
				}
			)

		case let .deleteResult(.failure(error)):
			errorQueue.schedule(error)
			state.errorText = "Failed to delete signaling server."
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .deleteAlert(.confirmTapped):
			guard
				let originalProfile = state.originalProfile,
				!state.isCurrent
			else {
				return .none
			}

			return .run { send in
				let result = await TaskResult {
					try await p2pTransportProfilesClient.removeProfile(originalProfile)
				}
				await send(.internal(.deleteResult(result)))
			}

		case .deleteAlert(.cancelTapped):
			return .none
		}
	}
}

extension AlertState<SignalingServerDetails.Destination.Action.DeleteAlert> {
	static let deleteConfirmation = AlertState {
		TextState("Remove Signaling Server")
	} actions: {
		ButtonState(role: .cancel, action: .cancelTapped) {
			TextState(L10n.Common.cancel)
		}
		ButtonState(role: .destructive, action: .confirmTapped) {
			TextState(L10n.Common.remove)
		}
	} message: {
		TextState("You will no longer be able to connect to this signaling server.")
	}
}

private extension SignalingServerDetails {
	struct MissingProfile: Error, LocalizedError {
		var errorDescription: String? {
			"Missing signaling server profile."
		}
	}

	func populate(state: inout State, with loadedProfile: LoadedProfile) {
		state.originalProfile = loadedProfile.profile
		state.isCurrent = loadedProfile.isCurrent
		state.name = loadedProfile.profile.name
		state.signalingServer = loadedProfile.profile.signalingServer
		state.stunURLs = .init(uniqueElements: loadedProfile.profile.stun.urls.map { State.URLFieldState(value: $0) })
		state.turnURLs = .init(uniqueElements: loadedProfile.profile.turn.urls.map { State.URLFieldState(value: $0) })
		state.turnUsername = loadedProfile.profile.turn.username ?? ""
		state.turnCredential = loadedProfile.profile.turn.credential ?? ""
	}

	func refreshSaveButtonState(state: inout State) {
		state.saveButtonState = canSave(state: state) ? .enabled : .disabled
	}

	func canSave(state: State) -> Bool {
		let trimmedName = state.name.trimmingCharacters(in: .whitespacesAndNewlines)
		let trimmedStunURLs = trimmedURLValues(state.stunURLs)
		let trimmedTurnURLs = trimmedURLValues(state.turnURLs)

		if trimmedStunURLs.contains(where: \.isEmpty) || trimmedTurnURLs.contains(where: \.isEmpty) {
			return false
		}

		switch state.mode {
		case .create:
			guard !trimmedName.isEmpty else { return false }
			return signalingURL(from: state.signalingServer) != nil

		case .edit:
			guard let originalProfile = state.originalProfile else { return false }
			return trimmedStunURLs != originalProfile.stun.urls
				|| trimmedTurnURLs != originalProfile.turn.urls
				|| optionalString(state.turnUsername) != originalProfile.turn.username
				|| optionalString(state.turnCredential) != originalProfile.turn.credential
		}
	}

	func makeProfile(from state: State) -> P2PTransportProfile? {
		let name = state.name.trimmingCharacters(in: .whitespacesAndNewlines)
		let signalingServer = if state.isEditMode {
			state.originalProfile?.signalingServer
		} else {
			signalingURL(from: state.signalingServer)?.absoluteString
		}

		guard
			let signalingServer,
			!name.isEmpty
		else {
			return nil
		}

		let turnURLs = trimmedURLValues(state.turnURLs)
		let hasTurnURLs = !turnURLs.isEmpty

		return P2PTransportProfile(
			name: name,
			signalingServer: signalingServer,
			stun: P2PStunServer(urls: trimmedURLValues(state.stunURLs)),
			turn: P2PTurnServer(
				urls: turnURLs,
				username: hasTurnURLs ? optionalString(state.turnUsername) : nil,
				credential: hasTurnURLs ? optionalString(state.turnCredential) : nil
			)
		)
	}

	func signalingURL(from input: String) -> URL? {
		let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty else { return nil }

		let value = if trimmed.contains("://") {
			trimmed
		} else {
			"wss://\(trimmed)"
		}

		guard
			let url = URL(string: value),
			let scheme = url.scheme?.lowercased(),
			["ws", "wss"].contains(scheme)
		else {
			return nil
		}

		return url
	}

	func trimmedURLValues(_ values: IdentifiedArrayOf<State.URLFieldState>) -> [String] {
		values.map { $0.value.trimmingCharacters(in: .whitespacesAndNewlines) }
			.filter { !$0.isEmpty }
	}

	func optionalString(_ value: String) -> String? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		return trimmed.isEmpty ? nil : trimmed
	}
}
