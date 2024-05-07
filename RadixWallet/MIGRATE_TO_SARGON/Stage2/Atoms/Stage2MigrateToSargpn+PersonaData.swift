import Foundation
import Sargon

extension PersonaData {
	public func responseValidation(
		for request: P2P.Dapp.Request.PersonaDataRequestItem
	) -> P2P.Dapp.Request.RequestValidation {
		let allExisting = Dictionary(grouping: entries.map(\.value), by: \.discriminator)

		var result = P2P.Dapp.Request.RequestValidation()
		for (kind, kindRequest) in request.kindRequests {
			let values = allExisting[kind] ?? []
			switch validate(values, for: kindRequest) {
			case let .left(missingEntry):
				result.missingEntries[kind] = missingEntry
			case let .right(responseValues):
				result.existingRequestedEntries[kind] = responseValues
			}
		}

		return result
	}

	private func validate(
		_ entries: [PersonaData.Entry],
		for request: P2P.Dapp.Request.KindRequest
	) -> Either<
		P2P.Dapp.Request.MissingEntry,
		[Entry]
	> {
		switch request {
		case .entry:
			guard let first = entries.first else { return .left(.missingEntry) }
			return .right([first])
		case let .number(number):
			let values = Set(entries.prefix(Int(number.quantity)))
			let missing = Int(number.quantity) - values.count
			guard missing <= 0 else { return .left(.missing(missing)) }
			return .right(Array(values))
		}
	}
}
