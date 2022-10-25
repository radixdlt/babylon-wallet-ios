//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-10-25.
//

import Foundation

// MARK: - Date + Sendable
extension Date: @unchecked Sendable {}

// MARK: - ExpectedHTTPURLResponse
struct ExpectedHTTPURLResponse: Swift.Error {}

// MARK: - BadHTTPResponseCode
struct BadHTTPResponseCode: Swift.Error {
	let got: Int
	let butExpected = Self.expected
	static let expected = 200
}

public extension GatewayAPIClient {
	static func live(
		baseURL: URL = .init(string: "https://alphanet.radixdlt.com/v0")!,
		urlSession: URLSession = .shared,
		jsonEncoder: JSONEncoder = .init(),
		jsonDecoder: JSONDecoder = .init()
	) -> Self {
		@Sendable
		func makeRequest<Response>(
			httpBodyData httpBody: Data?,
			method: String = "POST",
			responseType _: Response.Type,
			urlFromBase: (URL) -> URL
		) async throws -> Response where Response: Decodable {
			let url = urlFromBase(baseURL)
			print("📡 🛰 Network request: \(url.absoluteString)")
			var urlRequest = URLRequest(url: url)
			urlRequest.httpMethod = method
			if let httpBody {
				urlRequest.httpBody = httpBody
			}

			urlRequest.allHTTPHeaderFields = [
				"accept": "application/json",
				"Content-Type": "application/json",
			]

			let (data, urlResponse) = try await urlSession.data(for: urlRequest)

			guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
				throw ExpectedHTTPURLResponse()
			}

			guard httpURLResponse.statusCode == BadHTTPResponseCode.expected else {
				throw BadHTTPResponseCode(got: httpURLResponse.statusCode)
			}

			let response = try jsonDecoder.decode(Response.self, from: data)

			return response
		}

		@Sendable
		func makeRequest<Response>(
			httpBodyData httpBody: Data?,
			method: String = "POST",
			urlFromBase: @escaping (URL) -> URL
		) async throws -> Response where Response: Decodable {
			try await makeRequest(
				httpBodyData: httpBody,
				method: method,
				responseType: Response.self,
				urlFromBase: urlFromBase
			)
		}

		@Sendable
		func post<Response>(
			urlFromBase: @escaping (URL) -> URL
		) async throws -> Response where Response: Decodable {
			try await makeRequest(httpBodyData: nil, responseType: Response.self, urlFromBase: urlFromBase)
		}

		@Sendable
		func post<Request, Response>(
			request: Request,
			urlFromBase: @escaping (URL) -> URL
		) async throws -> Response
			where
			Request: Encodable, Response: Decodable
		{
			jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
			let httpBody = try jsonEncoder.encode(request)

			return try await makeRequest(httpBodyData: httpBody, urlFromBase: urlFromBase)
		}

		let getEpoch: GetEpoch = {
			try await post {
				$0
					.appendingPathComponent("state")
					.appendingPathComponent("epoch")
			}
		}

		return Self(
			getEpoch: getEpoch,
			accountResourcesByAddress: { accountAddress in
				try await post(
					request: V0StateComponentRequest(componentAddress: accountAddress.address)
				) { baseURL in
					baseURL
						.appendingPathComponent("state")
						.appendingPathComponent("component")
				}
			},
			resourceDetailsByResourceIdentifier: { resourceAddress in
				try await post(
					request: V0StateResourceRequest(resourceAddress: resourceAddress)
				) { baseURL in
					baseURL
						.appendingPathComponent("state")
						.appendingPathComponent("resource")
				}
			},
			submitTransaction: { transactionSubmitRequest in
				try await Self.mock().submitTransaction(transactionSubmitRequest)
			},
			transactionStatus: { transactionStatusRequest in
				try await Self.mock().transactionStatus(transactionStatusRequest)
			},
			getCommittedTransaction: { request in
				try await Self.mock().getCommittedTransaction(request)
			}
		)
	}
}
