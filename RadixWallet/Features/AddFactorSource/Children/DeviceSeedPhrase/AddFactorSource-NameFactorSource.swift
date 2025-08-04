// MARK: - AddFactorSource.NameFactorSource
extension AddFactorSource {
	@Reducer
	struct NameFactorSource: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			enum FactorSourceInput: Sendable, Hashable {
				case device(DeviceFactorSource, MnemonicWithPassphrase)
				case arculus(ArculusCardFactorSource, MnemonicWithPassphrase, String)
				case ledger(LedgerHardwareWalletFactorSource)

				var factorSource: FactorSource {
					switch self {
					case let .device(fs, _):
						fs.asGeneral
					case let .arculus(fs, _, _):
						fs.asGeneral
					case let .ledger(fs):
						fs.asGeneral
					}
				}
			}

			let context: Context
			var name: String = ""
			var sanitizedName: NonEmptyString?
			var isAddingFactorSource: Bool = false
			var factorSourceInput: FactorSourceInput

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
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.arculusCardClient) var arculusCardClient

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
				state.isAddingFactorSource = true

				return .run { [factorSourceInput = state.factorSourceInput] send in
					let result = await TaskResult {
						switch factorSourceInput {
						case let .device(fs, mwp):
							try secureStorageClient.saveMnemonicForFactorSource(
								.init(
									mnemonicWithPassphrase: mwp,
									factorSource: fs
								)
							)
							try? userDefaults.addFactorSourceIDOfBackedUpMnemonic(fs.id)

						case let .arculus(_, mwp, pin):
							_ = try await arculusCardClient.configureCardWithMnemonic(mwp.mnemonic, pin)

						case .ledger:
							break
						}

						var fs = factorSourceInput.factorSource
						fs.setName(name)

						_ = try await SargonOS.shared.addFactorSource(factorSource: fs)

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
			.send(.delegate(.saved(state.factorSourceInput.factorSource)))
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
