import ComposableArchitecture
import CreateAccountFeature
import ImportProfileFeature

// MARK: - Onboarding
public struct Onboarding: Sendable, ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.root, action: /Action.self) {
			EmptyReducer()
				.ifCaseLet(/Onboarding.State.Root.importProfile, action: /Action.importProfile) {
					ImportProfile()
				}
				.ifCaseLet(/Onboarding.State.Root.createAccount, action: /Action.createAccount) {
					CreateAccount()
				}
		}
	}
}
