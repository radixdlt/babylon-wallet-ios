extension AddFactorSource {
	@Reducer
	struct NameFactorSource: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			@Shared(.deviceMnemonicBuilder) var deviceMnemonicBuilder
			let kind: FactorSourceKind
			var name: String = ""
			var sanitizedName: NonEmptyString?
			var isAddingFactorSource: Bool = false

			@Presents
			var destination: Destination.State? = nil

			var saveButtonControlState: ControlState {
				if isAddingFactorSource {
					.loading(.local)
				} else if sanitizedName == nil {
					.disabled
				} else {
					.enabled
				}
			}
		}

		typealias Action = FeatureAction<Self>

		@CasePathable
		enum ViewAction: Sendable, Equatable {
			case nameChanged(String)
			case saveTapped(NonEmptyString)
		}

		enum InternalAction: Sendable, Equatable {
			case addFactorSourceResult(TaskResult<EqVoid>)
		}

		enum DelegateAction: Sendable, Equatable {
			case saved
		}

		struct Destination: DestinationReducer {
			@CasePathable
			enum State: Sendable, Hashable {
				case completion
			}

			@CasePathable
			enum Action: Sendable, Equatable {
				case completion
			}

			var body: some ReducerOf<Self> {
				EmptyReducer()
			}
		}

		@Dependency(\.errorQueue) var errorQueue
		@Dependency(\.userDefaults) var userDefaults

		var body: some ReducerOf<Self> {
			Reduce(core)
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case let .nameChanged(name):
				state.name = name
				state.sanitizedName = NonEmpty(rawValue: name.trimmingWhitespacesAndNewlines())
				return .none
			case let .saveTapped(name):
				let mwp = state.deviceMnemonicBuilder.getMnemonicWithPassphrase()
				let fsId = state.deviceMnemonicBuilder.getFactorSourceId()
				state.isAddingFactorSource = true
				return .run { send in
					let result = await TaskResult {
						_ = try await SargonOS.shared.addNewMnemonicFactorSource(factorSourceKind: .device, mnemonicWithPassphrase: mwp, name: name.rawValue)
						try? userDefaults.addFactorSourceIDOfBackedUpMnemonic(fsId.extract())
						return EqVoid.instance
					}
					await send(.internal(.addFactorSourceResult(result)))
				}
			}
		}

		func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
			switch internalAction {
			case .addFactorSourceResult(.success):
				state.destination = .completion
				return .none
			case let .addFactorSourceResult(.failure(error)):
				state.isAddingFactorSource = false
				errorQueue.schedule(error)
				return .none
			}
		}

		func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
			.send(.delegate(.saved))
		}
	}
}
