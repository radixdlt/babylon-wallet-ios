import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - RelayServicesSettings
struct RelayServicesSettings: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		struct Row: Sendable, Hashable, Identifiable {
			typealias ID = URL
			var id: URL {
				service.url
			}

			let service: RelayService
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
		case addServiceButtonTapped
		case rowTapped(URL)
		case rowRemoveTapped(URL)
	}

	enum InternalAction: Sendable, Equatable {
		case servicesLoaded(SavedRelayServices)
		case changeServiceResult(TaskResult<EqVoid>)
		case removeServiceResult(TaskResult<EqVoid>)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case addNewService(AddNewRelayService.State)
			case removeService(AlertState<Action.RemoveServiceAlert>)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case addNewService(AddNewRelayService.Action)
			case removeService(RemoveServiceAlert)

			enum RemoveServiceAlert: Sendable, Hashable {
				case removeButtonTapped(URL)
				case cancelButtonTapped
			}
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.addNewService, action: \.addNewService) {
				AddNewRelayService()
			}
		}
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.appPreferencesClient) var appPreferencesClient

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
				do {
					for try await preferences in await appPreferencesClient.appPreferenceUpdates() {
						guard !Task.isCancelled else { return }
						await send(.internal(.servicesLoaded(preferences.relayServices)))
					}
				} catch {
					errorQueue.schedule(error)
				}
			}

		case .addServiceButtonTapped:
			state.destination = .addNewService(.init())
			return .none

		case let .rowTapped(id):
			guard
				let row = state.rows[id: id],
				!row.isSelected
			else { return .none }
			return .run { send in
				let result = await TaskResult {
					try await appPreferencesClient.updating { appPreferences in
						var services = appPreferences.relayServices
						let changed = services.changeCurrent(to: row.service)
						guard changed else { return }
						appPreferences.relayServices = services
					}
					return EqVoid.instance
				}
				await send(.internal(.changeServiceResult(result)))
			}

		case let .rowRemoveTapped(id):
			state.destination = .removeService(.removeService(id: id))
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .servicesLoaded(services):
			let all = services.all
			let sorted = all.sorted { lhs, rhs in
				let lhsName = lhs.name.lowercased()
				let rhsName = rhs.name.lowercased()
				if lhsName != rhsName {
					return lhsName < rhsName
				}
				return lhs.url.absoluteString < rhs.url.absoluteString
			}

			state.rows = .init(uniqueElements: sorted.map { service in
				.init(
					service: service,
					isSelected: service.url.absoluteString == services.current.url.absoluteString,
					canBeDeleted: all.count > 1
				)
			})
			return .none

		case let .changeServiceResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case .changeServiceResult(.success):
			return .none

		case let .removeServiceResult(.failure(error)):
			errorQueue.schedule(error)
			return .none

		case .removeServiceResult(.success):
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .removeService(action):
			switch action {
			case let .removeButtonTapped(id):
				guard let row = state.rows[id: id], state.rows.count > 1 else {
					return .none
				}

				if row.isSelected {
					guard let fallback = state.rows.first(where: { $0.id != id })?.service else {
						return .none
					}
					return .run { send in
						let result = await TaskResult {
							try await appPreferencesClient.updating { appPreferences in
								var services = appPreferences.relayServices
								let changed = services.changeCurrent(to: fallback)
								guard changed else { return }
								let removed = services.remove(row.service)
								guard removed else { return }
								appPreferences.relayServices = services
							}
							return EqVoid.instance
						}
						await send(.internal(.removeServiceResult(result)))
					}
				}

				return .run { send in
					let result = await TaskResult {
						try await appPreferencesClient.updating { appPreferences in
							var services = appPreferences.relayServices
							let removed = services.remove(row.service)
							guard removed else { return }
							appPreferences.relayServices = services
						}
						return EqVoid.instance
					}
					await send(.internal(.removeServiceResult(result)))
				}

			case .cancelButtonTapped:
				return .none
			}

		default:
			return .none
		}
	}
}

extension AlertState<RelayServicesSettings.Destination.Action.RemoveServiceAlert> {
	static func removeService(id: URL) -> AlertState {
		AlertState {
			TextState("Remove relay service?")
		} actions: {
			ButtonState(role: .cancel, action: .cancelButtonTapped) {
				TextState(L10n.Common.cancel)
			}
			ButtonState(action: .removeButtonTapped(id)) {
				TextState(L10n.Common.remove)
			}
		} message: {
			TextState("This will remove the relay service endpoint.")
		}
	}
}

// MARK: - AddNewRelayService
@Reducer
struct AddNewRelayService: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		enum Field: String, Sendable, Hashable {
			case name
			case relayURL
		}

		var focusedField: Field?
		var name: String = ""
		var relayURL: String = ""
		var errorText: String?
		var addButtonState: ControlState = .disabled
		var parsedRelayURL: URL?
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case appeared
		case textFieldFocused(State.Field?)
		case nameChanged(String)
		case relayURLChanged(String)
		case addButtonTapped
	}

	enum InternalAction: Sendable, Equatable {
		case focusTextField(State.Field?)
		case addServiceResult(TaskResult<EqVoid>)
		case showDuplicateURLError
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.isPresented) var isPresented
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.appPreferencesClient) var appPreferencesClient

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

		case let .relayURLChanged(value):
			state.relayURL = value
			refreshValidation(state: &state)
			return .none

		case .addButtonTapped:
			guard let parsedRelayURL = state.parsedRelayURL else { return .none }
			let trimmedName = state.name.trimmingCharacters(in: .whitespacesAndNewlines)
			let newService = RelayService(name: trimmedName, url: parsedRelayURL)

			return .run { send in
				let hasService = await appPreferencesClient
					.getPreferences()
					.relayServices
					.all
					.contains(where: { $0.url.absoluteString == parsedRelayURL.absoluteString })
				if hasService {
					await send(.internal(.showDuplicateURLError))
					return
				}

				let result = await TaskResult {
					try await appPreferencesClient.updating { appPreferences in
						var services = appPreferences.relayServices
						let inserted = services.append(newService)
						guard inserted else { return }
						appPreferences.relayServices = services
					}
					return EqVoid.instance
				}
				await send(.internal(.addServiceResult(result)))
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .focusTextField(focus):
			state.focusedField = focus
			return .none

		case .showDuplicateURLError:
			state.errorText = "A relay service with this URL already exists."
			state.addButtonState = .disabled
			return .none

		case .addServiceResult(.success):
			return .run { _ in
				if isPresented {
					await dismiss()
				}
			}

		case let .addServiceResult(.failure(error)):
			state.errorText = "Failed to add relay service."
			state.addButtonState = .disabled
			errorQueue.schedule(error)
			return .none
		}
	}
}

private extension AddNewRelayService {
	func refreshValidation(state: inout State) {
		state.errorText = nil

		let trimmedName = state.name.trimmingCharacters(in: .whitespacesAndNewlines)
		guard
			!trimmedName.isEmpty,
			let parsedURL = relayURL(from: state.relayURL)
		else {
			state.parsedRelayURL = nil
			state.addButtonState = .disabled
			return
		}

		state.parsedRelayURL = parsedURL
		state.addButtonState = .enabled
	}

	func relayURL(from input: String) -> URL? {
		let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty else { return nil }

		let withScheme: String = if trimmed.contains("://") {
			trimmed
		} else {
			"https://\(trimmed)"
		}

		guard
			let url = URL(string: withScheme),
			let scheme = url.scheme?.lowercased(),
			["http", "https"].contains(scheme)
		else { return nil }

		return url
	}
}

private extension SavedRelayServices {
	var all: [RelayService] {
		[current] + other
	}

	@discardableResult
	mutating func append(_ service: RelayService) -> Bool {
		guard !all.contains(where: { $0.url.absoluteString == service.url.absoluteString }) else {
			return false
		}
		other.append(service)
		return true
	}

	@discardableResult
	mutating func remove(_ service: RelayService) -> Bool {
		let oldCount = other.count
		other.removeAll(where: { $0.url.absoluteString == service.url.absoluteString })
		return oldCount != other.count
	}

	@discardableResult
	mutating func changeCurrent(to service: RelayService) -> Bool {
		guard current.url.absoluteString != service.url.absoluteString else {
			return false
		}

		let oldCurrent = current
		other.removeAll(where: { $0.url.absoluteString == service.url.absoluteString })
		current = service

		if !other.contains(where: { $0.url.absoluteString == oldCurrent.url.absoluteString }) {
			other.append(oldCurrent)
		}
		return true
	}
}
