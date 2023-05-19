import Cryptography
import DerivePublicKeyFeature
import FeaturePrelude
import PersonasClient

public struct CreationOfPersona: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let name: NonEmptyString
		public let fields: IdentifiedArrayOf<Profile.Network.Persona.Field>
		public var derivePublicKey: DerivePublicKey.State

		public init(
			name: NonEmptyString,
			fields: IdentifiedArrayOf<Profile.Network.Persona.Field>
		) {
			self.name = name
			self.fields = fields
			self.derivePublicKey = .init(
				derivationPathOption: .nextBasedOnFactorSource(networkOption: .useCurrent),
				factorSourceOption: .device,
				loadMnemonicPurpose: .createEntity(kind: .identity)
			)
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case createPersonaResult(TaskResult<Profile.Network.Persona>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case createdPersona(Profile.Network.Persona)
		case createPersonaFailed
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.personasClient) var personasClient

	public init() {}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .createPersonaResult(.failure(error)):
			errorQueue.schedule(error)
			return .send(.delegate(.createPersonaFailed))

		case let .createPersonaResult(.success(persona)):
			return .send(.delegate(.createdPersona(persona)))
		}
	}
}
