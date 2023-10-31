import EngineToolkit
@testable import Radix_Wallet_Dev
import XCTest

@MainActor
final class AssetTransferDepositRuleTests: TestCase {
	static let recipientAccount = Profile.Network.Account.testValueIdx0
	static let resourceAddress = try! ResourceAddress(validatingAddress: "resource_rdx1tkk83magp3gjyxrpskfsqwkg4g949rmcjee4tu2xmw93ltw2cz94sq")

	static let onLedgerAccountWithResource = OnLedgerEntity.Account(
		address: recipientAccount.address,
		atLedgerState: .init(version: 0, epoch: 0),
		metadata: .init(nil),
		fungibleResources: .init(
			xrdResource: .init(
				resourceAddress: resourceAddress,
				atLedgerState: .init(version: 0, epoch: 0),
				amount: .one(),
				metadata: .init(nil)
			)
		),
		nonFungibleResources: [],
		poolUnitResources: .init(radixNetworkStakes: [], poolUnits: [])
	)

	// MARK: - AcceptAll deposit rule
	func test_GIVEN_depositRuleIsAcceptAll_WHEN_resourceHasNoException_THEN_noSignatureIsRequired() async {
		var account = Self.recipientAccount
		account.onLedgerSettings.thirdPartyDeposits.depositRule = .acceptAll

		await assertNoSignatureIsRequired(for: account)
	}

	func test_GIVEN_depositRuleIsAcceptAll_WHEN_resourceIsInAllowList_THEN_noSignatureIsRequired() async {
		var account = Self.recipientAccount
		account.onLedgerSettings.thirdPartyDeposits.depositRule = .acceptAll
		account.onLedgerSettings.thirdPartyDeposits.assetsExceptionList = [.init(address: Self.resourceAddress, exceptionRule: .allow)]

		await assertNoSignatureIsRequired(for: account)
	}

	func test_GIVEN_depositRuleIsAcceptAll_WHEN_resourceIsInDenyList_THEN_signatureIsRequired() async {
		var account = Self.recipientAccount
		account.onLedgerSettings.thirdPartyDeposits.depositRule = .acceptAll
		account.onLedgerSettings.thirdPartyDeposits.assetsExceptionList = [.init(address: Self.resourceAddress, exceptionRule: .deny)]

		await assertSignatureIsRequired(for: account)
	}

	// MARK: - DenyAll deposit rule

	func test_GIVEN_depositRuleIsDenyAll_WHEN_resourceHasNoException_THEN_signatureIsRequired() async {
		var account = Self.recipientAccount
		account.onLedgerSettings.thirdPartyDeposits.depositRule = .denyAll

		await assertSignatureIsRequired(for: account)
	}

	func test_GIVEN_depositRuleIsDenyAll_WHEN_resourceIsInAllowList_THEN_noSignatureIsRequired() async {
		var account = Self.recipientAccount
		account.onLedgerSettings.thirdPartyDeposits.depositRule = .denyAll
		account.onLedgerSettings.thirdPartyDeposits.assetsExceptionList = [.init(address: Self.resourceAddress, exceptionRule: .allow)]

		await assertNoSignatureIsRequired(for: account)
	}

	func test_GIVEN_depositRuleIsDenyAll_WHEN_resourceIsInDenyList_THEN_signatureIsRequired() async {
		var account = Self.recipientAccount
		account.onLedgerSettings.thirdPartyDeposits.depositRule = .denyAll
		account.onLedgerSettings.thirdPartyDeposits.assetsExceptionList = [.init(address: Self.resourceAddress, exceptionRule: .deny)]

		await assertSignatureIsRequired(for: account)
	}

	// MARK: - AcceptKnown deposit rule

	func test_GIVEN_depositRuleIsAcceptKnown_WHEN_accountDoesNotContainResource_resourceHasNoException_THEN_signatureIsRequired() async {
		var account = Self.recipientAccount
		account.onLedgerSettings.thirdPartyDeposits.depositRule = .acceptKnown

		await assertSignatureIsRequired(for: account)
	}

	func test_GIVEN_depositRuleIsAcceptKnown_WHEN_accountDoesNotContainResource_resourceIsInAllowList_THEN_noSignatureIsRequired() async {
		var account = Self.recipientAccount
		account.onLedgerSettings.thirdPartyDeposits.depositRule = .acceptKnown
		account.onLedgerSettings.thirdPartyDeposits.assetsExceptionList = [.init(address: Self.resourceAddress, exceptionRule: .allow)]

		await assertNoSignatureIsRequired(for: account)
	}

	func test_GIVEN_depositRuleIsAcceptKnown_WHEN_accountDoesNotContainResource_resourceIsInDenyList_THEN_signatureIsRequired() async {
		var account = Self.recipientAccount
		account.onLedgerSettings.thirdPartyDeposits.depositRule = .acceptKnown
		account.onLedgerSettings.thirdPartyDeposits.assetsExceptionList = [.init(address: Self.resourceAddress, exceptionRule: .deny)]

		await assertSignatureIsRequired(for: account)
	}

	func test_GIVEN_depositRuleIsAcceptKnown_WHEN_accountContainResource_resourceHasNoException_THEN_noSignatureIsRequired() async {
		var account = Self.recipientAccount
		account.onLedgerSettings.thirdPartyDeposits.depositRule = .acceptKnown

		await assertNoSignatureIsRequired(for: account, onLedgerAccounts: [Self.onLedgerAccountWithResource])
	}

	func test_GIVEN_depositRuleIsAcceptKnown_WHEN_accountContainResource_resourceIsInAllowList_THEN_noSignatureIsRequired() async {
		var account = Self.recipientAccount
		account.onLedgerSettings.thirdPartyDeposits.depositRule = .acceptKnown
		account.onLedgerSettings.thirdPartyDeposits.assetsExceptionList = [.init(address: Self.resourceAddress, exceptionRule: .allow)]

		await assertNoSignatureIsRequired(for: account, onLedgerAccounts: [Self.onLedgerAccountWithResource])
	}

	func test_GIVEN_depositRuleIsAcceptKnown_WHEN_accountContainResource_resourceIsInDenyList_THEN_signatureIsRequired() async {
		var account = Self.recipientAccount
		account.onLedgerSettings.thirdPartyDeposits.depositRule = .acceptKnown
		account.onLedgerSettings.thirdPartyDeposits.assetsExceptionList = [.init(address: Self.resourceAddress, exceptionRule: .deny)]

		await assertSignatureIsRequired(for: account, onLedgerAccounts: [Self.onLedgerAccountWithResource])
	}

	// MARK: - Private

	private func assertSignatureIsRequired(for account: Profile.Network.Account, onLedgerAccounts: [OnLedgerEntity.Account] = []) async {
		await assertSignatureIsRequired(for: account, isRequired: true, onLedgerAccounts: onLedgerAccounts)
	}

	private func assertNoSignatureIsRequired(for account: Profile.Network.Account, onLedgerAccounts: [OnLedgerEntity.Account] = []) async {
		await assertSignatureIsRequired(for: account, isRequired: false, onLedgerAccounts: onLedgerAccounts)
	}

	private func assertSignatureIsRequired(for account: Profile.Network.Account, isRequired: Bool, onLedgerAccounts: [OnLedgerEntity.Account]) async {
		await withDependencies { d in
			d.onLedgerEntitiesClient.getEntities = { _, _, _, _ in
				onLedgerAccounts.map { .account($0) }
			}
		} operation: {
			let result = await needsSignatureForDepositting(into: account, resource: Self.resourceAddress)
			XCTAssertEqual(isRequired, result)
		}
	}
}
