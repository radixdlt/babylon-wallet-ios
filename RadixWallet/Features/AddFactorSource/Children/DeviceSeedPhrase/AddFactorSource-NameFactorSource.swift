// MARK: - AddFactorSource.NameFactorSource
extension AddFactorSource {
	@Reducer
	struct NameFactorSource: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			var name: String = ""
			var sanitizedName: NonEmptyString?
			var isAddingFactorSource: Bool = false
			var factorSource: FactorSource

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
			case saved(FactorSource)
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
				state.factorSource.setName(name)
				state.isAddingFactorSource = true
				return .run { [factorSource = state.factorSource] send in
					let result = await TaskResult {
						_ = try await SargonOS.shared.addFactorSource(factorSource: factorSource)
						if factorSource.factorSourceKind == .device {
							try? userDefaults.addFactorSourceIDOfBackedUpMnemonic(factorSource.id.extract())
						}
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
			.send(.delegate(.saved(state.factorSource)))
		}
	}
}

extension FactorSource {
	mutating func setName(_ name: NonEmptyString) {
		switch self {
		case var .device(value):
			value.hint.label = name.stringValue
			self = .device(value: value)
		case var .ledger(value):
			value.hint.label = name.stringValue
			self = .ledger(value: value)
		case var .offDeviceMnemonic(value):
			value.hint.label = DisplayName(nonEmpty: name)
			self = .offDeviceMnemonic(value: value)
		case var .arculusCard(value):
			value.hint.label = name.stringValue
			self = .arculusCard(value: value)
		case var .password(value):
			value.hint.label = name.stringValue
			self = .password(value: value)
		}
	}
}
