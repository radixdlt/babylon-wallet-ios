import ComposableArchitecture
@testable import Radix_Wallet_Dev
import Sargon
import XCTest

final class TokenPriceCientTests: XCTestCase {
	func test_fetchPricesRequestStillCarriesOnlyTokensAndCurrency() throws {
		let resourceAddress = try ResourceAddress(validatingAddress: "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd")
		let request = TokenPricesClient.FetchPricesRequest(
			tokens: [resourceAddress],
			currency: .usd
		)

		let encoded = try JSONEncoder().encode(request)
		let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])

		XCTAssertEqual(json["currency"] as? String, FiatCurrency.usd.rawValue)
		XCTAssertEqual(json["tokens"] as? [String], [resourceAddress.address])
		XCTAssertNil(json["lsus"])
	}

	func test_tokenPriceServiceURLAddsHTTPSByDefault() {
		XCTAssertEqual(
			AddTokenPriceService.tokenPriceServiceURL(from: "prices.example.com", isDeveloperModeEnabled: false)?.absoluteString,
			"https://prices.example.com"
		)
	}

	func test_tokenPriceServiceURLAllowsHTTPInDeveloperMode() {
		XCTAssertEqual(
			AddTokenPriceService.tokenPriceServiceURL(from: "localhost:8080", isDeveloperModeEnabled: true)?.absoluteString,
			"http://localhost:8080"
		)
	}

	func test_tokenPriceServiceURLRejectsLocalhostOutsideDeveloperMode() {
		XCTAssertNil(AddTokenPriceService.tokenPriceServiceURL(from: "localhost:8080", isDeveloperModeEnabled: false))
		XCTAssertNil(AddTokenPriceService.tokenPriceServiceURL(from: "https://localhost:8080", isDeveloperModeEnabled: false))
	}

	func test_tokenPriceServiceURLRejectsIPAddressesOutsideDeveloperMode() {
		XCTAssertNil(AddTokenPriceService.tokenPriceServiceURL(from: "127.0.0.1", isDeveloperModeEnabled: false))
		XCTAssertNil(AddTokenPriceService.tokenPriceServiceURL(from: "https://192.168.0.10", isDeveloperModeEnabled: false))
		XCTAssertNil(AddTokenPriceService.tokenPriceServiceURL(from: "https://[2001:db8::1]", isDeveloperModeEnabled: false))
	}

	func test_tokenPriceServiceURLRejectsCustomPortsOutsideDeveloperMode() {
		XCTAssertNil(AddTokenPriceService.tokenPriceServiceURL(from: "prices.example.com:8443", isDeveloperModeEnabled: false))
		XCTAssertNil(AddTokenPriceService.tokenPriceServiceURL(from: "https://prices.example.com:8443", isDeveloperModeEnabled: false))
	}

	func test_tokenPriceServiceURLRejectsHTTPOutsideDeveloperMode() {
		XCTAssertNil(AddTokenPriceService.tokenPriceServiceURL(from: "http://prices.example.com", isDeveloperModeEnabled: false))
	}

	func test_tokenPriceServiceURLRejectsUnsupportedSchemes() {
		XCTAssertNil(AddTokenPriceService.tokenPriceServiceURL(from: "ftp://prices.example.com", isDeveloperModeEnabled: true))
	}

	@MainActor
	func test_deleteTappedDoesNotPresentAlertForOnlyTokenPriceService() async throws {
		let service = try TokenPriceService(baseUrl: XCTUnwrap(URL(string: "https://prices.example.com")))
		var state = TokenPriceServicesSettings.State()
		state.rows = .init(uniqueElements: [.init(service: service)])
		let store = TestStore(
			initialState: state,
			reducer: TokenPriceServicesSettings.init
		)

		await store.send(.view(.deleteTapped(service.baseUrl)))
	}

	@MainActor
	func test_removeConfirmationDoesNotDeleteOnlyTokenPriceService() async throws {
		let service = try TokenPriceService(baseUrl: XCTUnwrap(URL(string: "https://prices.example.com")))
		let didDelete = ActorIsolated(false)
		var state = TokenPriceServicesSettings.State()
		state.rows = .init(uniqueElements: [.init(service: service)])
		state.destination = .deleteAlert(.removeService(baseURL: service.baseUrl))
		let store = TestStore(
			initialState: state,
			reducer: TokenPriceServicesSettings.init
		) {
			$0.tokenPricesClient.deleteTokenPriceService = { _ in
				await didDelete.setValue(true)
				return true
			}
		}

		await store.send(.destination(.presented(.deleteAlert(.removeButtonTapped(service.baseUrl))))) {
			$0.destination = nil
		}
		await XCTFalse(didDelete.value)
	}
}
