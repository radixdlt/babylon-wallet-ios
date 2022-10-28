@testable import AccountDetailsFeature
import AccountListFeature
import ComposableArchitecture
import Profile
import TestUtils

@MainActor
final class AccountDetailsFeatureTests: TestCase {
	let account = try! OnNetwork.Account(
		address: OnNetwork.Account.EntityAddress(
			address: "account_tdx_a_1qwv0unmwmxschqj8sntg6n9eejkrr6yr6fa4ekxazdzqhm6wy5"
		),
		securityState: .unsecured(.init(
			genesisFactorInstance: .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance(.init(
				factorSourceReference: .init(
					factorSourceKind: .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSourceKind,
					factorSourceID: "09bfa80bcc9b75d6ad82d59730f7b179cbc668ba6ad4008721d5e6a179ff55f1"
				),
				publicKey: .eddsaEd25519(.init(
					compressedRepresentation: Data(
						hex: "7bf9f97c0cac8c6c112d716069ccc169283b9838fa2f951c625b3d4ca0a8f05b")
				)),
				derivationPath: .accountPath(.init(derivationPath: "m/44H/1022H/10H/525H/0H/1238H"))
			)
			)
		)),
		index: 0,
		derivationPath: .init(derivationPath: "m/44H/1022H/10H/525H/0H/1238H"),
		displayName: "Main"
	)

	func test_dismissAccountDetails_whenTappedOnBackButton_thenCoordinateDismissal() async {
		// given
		let accountListRowState = AccountList.Row.State(account: account)
		let initialState = AccountDetails.State(for: accountListRowState)
		let store = TestStore(
			initialState: initialState,
			reducer: AccountDetails.reducer,
			environment: .unimplemented
		)

		// when
		_ = await store.send(.internal(.user(.dismissAccountDetails)))

		// then
		await store.receive(.coordinate(.dismissAccountDetails))
	}

	func test_navigateToAccountPreferences_whenTappedOnPreferencesButton_thenCoordinateNavigationToPreferences() async {
		// given

		let accountListRowState = AccountList.Row.State(account: account)
		let initialState = AccountDetails.State(for: accountListRowState)
		let store = TestStore(
			initialState: initialState,
			reducer: AccountDetails.reducer,
			environment: .unimplemented
		)

		// when
		_ = await store.send(.internal(.user(.displayAccountPreferences)))

		// then
		await store.receive(.coordinate(.displayAccountPreferences))
	}

	func test_copyAddress_whenTappedOnCopyAddress_thenCoordiateCopiedAddress() async {
		// given

		let accountListRowState = AccountList.Row.State(account: account)
		let initialState = AccountDetails.State(for: accountListRowState)
		let store = TestStore(
			initialState: initialState,
			reducer: AccountDetails.reducer,
			environment: .unimplemented
		)

		// when
		_ = await store.send(.internal(.user(.copyAddress)))

		// then
		await store.receive(.coordinate(.copyAddress(store.state.address)))
	}

	func test_refresh_whenInitiatedRefresh_thenCoordinateRefreshForAddress() async {
		// given

		let accountListRowState = AccountList.Row.State(account: account)
		let initialState = AccountDetails.State(for: accountListRowState)
		let store = TestStore(
			initialState: initialState,
			reducer: AccountDetails.reducer,
			environment: .unimplemented
		)

		// when
		_ = await store.send(.internal(.user(.refresh)))

		// then
		await store.receive(.coordinate(.refresh(store.state.address)))
	}

	func test_displayTransfer_whenTappedOnDisplayTransfer_thenCoordinateNavigationToTransfer() async {
		// given

		let accountListRowState = AccountList.Row.State(account: account)
		let initialState = AccountDetails.State(for: accountListRowState)
		let store = TestStore(
			initialState: initialState,
			reducer: AccountDetails.reducer,
			environment: .unimplemented
		)

		// when
		_ = await store.send(.internal(.user(.displayTransfer)))

		await store.receive(.coordinate(.displayTransfer))
	}
}
