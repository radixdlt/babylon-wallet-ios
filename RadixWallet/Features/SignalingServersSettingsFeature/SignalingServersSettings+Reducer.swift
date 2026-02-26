import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - SignalingServersSettings
struct SignalingServersSettings: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		struct Row: Sendable, Hashable, Identifiable {
			typealias ID = String
			var id: String {
				profile.signalingServer
			}

			let profile: P2PTransportProfile
			var isSelected: Bool
			var canBeDeleted: Bool
		}

		var rows: IdentifiedArrayOf<Row> = []

		@Presents
		var destination: Destination.State? = nil
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case task
		case addProfileButtonTapped
		case rowTapped(String)
		case rowRemoveTapped(String)
	}

	enum InternalAction: Sendable, Equatable {
		case profilesLoaded(TaskResult<SavedP2PTransportProfiles>)
		case changeProfileResult(TaskResult<EqVoid>)
		case removeProfileResult(TaskResult<EqVoid>)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case addNewProfile(AddNewSignalingServer.State)
			case removeProfile(AlertState<Action.RemoveProfileAlert>)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case addNewProfile(AddNewSignalingServer.Action)
			case removeProfile(RemoveProfileAlert)

			enum RemoveProfileAlert: Sendable, Hashable {
				case removeButtonTapped(String)
				case cancelButtonTapped
			}
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.addNewProfile, action: \.addNewProfile) {
				AddNewSignalingServer()
			}
		}
	}

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
			return .run { send in
				for try await profiles in await p2pTransportProfilesClient.p2pTransportProfilesValues() {
					guard !Task.isCancelled else { return }
					await send(.internal(.profilesLoaded(.success(profiles))))
				}
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case .addProfileButtonTapped:
			state.destination = .addNewProfile(.init())
			return .none

		case let .rowTapped(id):
			guard
				let row = state.rows[id: id],
				!row.isSelected
			else { return .none }
			return .run { send in
				let result = await TaskResult {
					try await p2pTransportProfilesClient.changeProfile(row.profile)
					return EqVoid.instance
				}
				await send(.internal(.changeProfileResult(result)))
			}

		case let .rowRemoveTapped(id):
			state.destination = .removeProfile(.removeProfile(id: id))
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .profilesLoaded(.success(profiles)):
			let all = profiles.all
			let sorted = all.sorted { lhs, rhs in
				let lhsName = lhs.name.lowercased()
				let rhsName = rhs.name.lowercased()
				if lhsName != rhsName {
					return lhsName < rhsName
				}
				return lhs.signalingServer < rhs.signalingServer
			}

			state.rows = .init(uniqueElements: sorted.map { profile in
				.init(
					profile: profile,
					isSelected: profile.signalingServer == profiles.current.signalingServer,
					canBeDeleted: all.count > 1
				)
			})
			return .none

		case let .profilesLoaded(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case let .changeProfileResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case .changeProfileResult(.success):
			return .none

		case let .removeProfileResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case .removeProfileResult(.success):
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .removeProfile(action):
			switch action {
			case let .removeButtonTapped(id):
				guard let row = state.rows[id: id], state.rows.count > 1 else {
					return .none
				}

				if row.isSelected {
					guard let fallback = state.rows.first(where: { $0.id != id })?.profile else {
						return .none
					}
					return .run { send in
						let result = await TaskResult {
							try await p2pTransportProfilesClient.changeProfile(fallback)
							try await p2pTransportProfilesClient.removeProfile(row.profile)
							return EqVoid.instance
						}
						await send(.internal(.removeProfileResult(result)))
					}
				}

				return .run { send in
					let result = await TaskResult {
						try await p2pTransportProfilesClient.removeProfile(row.profile)
						return EqVoid.instance
					}
					await send(.internal(.removeProfileResult(result)))
				}

			case .cancelButtonTapped:
				return .none
			}

		default:
			return .none
		}
	}
}

extension AlertState<SignalingServersSettings.Destination.Action.RemoveProfileAlert> {
	static func removeProfile(id: String) -> AlertState {
		AlertState {
			TextState("Remove signaling server?")
		} actions: {
			ButtonState(role: .cancel, action: .cancelButtonTapped) {
				TextState(L10n.Common.cancel)
			}
			ButtonState(action: .removeButtonTapped(id)) {
				TextState(L10n.Common.remove)
			}
		} message: {
			TextState("This will remove the signaling server profile.")
		}
	}
}

// MARK: - AddNewSignalingServer
@Reducer
struct AddNewSignalingServer: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		enum Field: String, Sendable, Hashable {
			case name
			case signalingURL
			case iceServerURLs
			case username
			case credential
		}

		var focusedField: Field?
		var name: String = ""
		var signalingURL: String = ""
		var iceServerURLs: String = ""
		var username: String = ""
		var credential: String = ""
		var errorText: String?
		var addButtonState: ControlState = .disabled
		var signalingFfiUrl: FfiUrl?
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case appeared
		case textFieldFocused(State.Field?)
		case nameChanged(String)
		case signalingURLChanged(String)
		case iceServerURLsChanged(String)
		case usernameChanged(String)
		case credentialChanged(String)
		case addButtonTapped
	}

	enum InternalAction: Sendable, Equatable {
		case focusTextField(State.Field?)
		case addProfileResult(TaskResult<EqVoid>)
		case showDuplicateURLError
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.isPresented) var isPresented
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.p2pTransportProfilesClient) var p2pTransportProfilesClient

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .send(.internal(.focusTextField(.name)))

		case let .textFieldFocused(focus):
			return .send(.internal(.focusTextField(focus)))

		case let .nameChanged(value):
			state.name = value
			refreshValidation(state: &state)
			return .none

		case let .signalingURLChanged(value):
			state.signalingURL = value
			refreshValidation(state: &state)
			return .none

		case let .iceServerURLsChanged(value):
			state.iceServerURLs = value
			refreshValidation(state: &state)
			return .none

		case let .usernameChanged(value):
			state.username = value
			return .none

		case let .credentialChanged(value):
			state.credential = value
			return .none

		case .addButtonTapped:
			guard let signalingFfiUrl = state.signalingFfiUrl else { return .none }
			let trimmedName = state.name.trimmingCharacters(in: .whitespacesAndNewlines)
			let urls = iceURLs(from: state.iceServerURLs)

			let username = optionalString(state.username)
			let credential = optionalString(state.credential)
			let stunURLs = urls.filter { $0.lowercased().hasPrefix("stun:") }
			let turnURLs = urls.filter { $0.lowercased().hasPrefix("turn:") }
			let fallbackStunURLs = if stunURLs.isEmpty, turnURLs.isEmpty {
				urls
			} else {
				stunURLs
			}
			let stun = P2PStunServer(urls: fallbackStunURLs)
			let turn = P2PTurnServer(urls: turnURLs, username: username, credential: credential)

			let newProfile = P2PTransportProfile(
				name: trimmedName,
				signalingServer: signalingFfiUrl.url.absoluteString,
				stun: stun,
				turn: turn
			)

			return .run { send in
				let hasProfile = await p2pTransportProfilesClient.hasProfileWithSignalingServerURL(signalingFfiUrl)
				if hasProfile {
					await send(.internal(.showDuplicateURLError))
					return
				}

				let result = await TaskResult {
					try await p2pTransportProfilesClient.addProfile(newProfile)
					return EqVoid.instance
				}
				await send(.internal(.addProfileResult(result)))
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .focusTextField(focus):
			state.focusedField = focus
			return .none

		case .showDuplicateURLError:
			state.errorText = "A signaling server with this URL already exists."
			state.addButtonState = .disabled
			return .none

		case .addProfileResult(.success):
			return .run { _ in
				if isPresented {
					await dismiss()
				}
			}

		case let .addProfileResult(.failure(error)):
			state.errorText = "Failed to add signaling server."
			state.addButtonState = .disabled
			errorQueue.schedule(error)
			return .none
		}
	}
}

private extension AddNewSignalingServer {
	func refreshValidation(state: inout State) {
		state.errorText = nil

		let trimmedName = state.name.trimmingCharacters(in: .whitespacesAndNewlines)
		guard
			!trimmedName.isEmpty,
			let parsedURL = signalingURL(from: state.signalingURL),
			let ffiUrl = try? FfiUrl(urlPath: parsedURL.absoluteString)
		else {
			state.signalingFfiUrl = nil
			state.addButtonState = .disabled
			return
		}

		state.signalingFfiUrl = ffiUrl
		state.addButtonState = .enabled
	}

	func signalingURL(from input: String) -> URL? {
		let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty else { return nil }

		let withScheme: String = if trimmed.contains("://") {
			trimmed
		} else {
			"wss://\(trimmed)"
		}

		guard
			let url = URL(string: withScheme),
			let scheme = url.scheme?.lowercased(),
			["ws", "wss"].contains(scheme)
		else { return nil }

		return url
	}

	func iceURLs(from input: String) -> [String] {
		input
			.split(whereSeparator: { $0 == "," || $0.isNewline })
			.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
			.filter { !$0.isEmpty }
	}

	func optionalString(_ value: String) -> String? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		return trimmed.isEmpty ? nil : trimmed
	}
}
