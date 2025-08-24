import AVFoundation
import CoreNFC
import SargonUniFFI

// MARK: - NFCTagReaderSession + @unchecked @retroactive Sendable
extension NFCTagReaderSession: @unchecked @retroactive Sendable {}

// MARK: - NFCSessionClient
public actor NFCSessionClient {
	static let supportedAIDs = Set([
		"4A4E45545F4C5F010157",
		"415243554C5553010157",
		"4A4E45545F4C5F010141000000010001",
		"4A4E45545F4C5F0101413C0000012C01",
		"4A4E45545F4C5F010141900000012C01",
	])

	var delegate: NFCTagReaderSessionAsyncDelegate?
	var session: NFCTagReaderSession?
	var isoTag: NFCISO7816Tag?
	var purpose: NfcTagDriverPurpose?

	var sessionStartTime: Date = .now
	var sessionRenewTime: Date = .now
	var signingRequestWasTriggered: Bool = false

	func setSigningRequestWasTriggered(_ trigger: Bool) {
		self.signingRequestWasTriggered = trigger
	}

	func setIsoTag(tag: NFCISO7816Tag?) async {
		self.isoTag = tag
	}

	func setSesssionStartTime(date: Date) async {
		self.sessionStartTime = date
	}

	func setSesssionRenewTime(date: Date) async {
		self.sessionRenewTime = date
	}
}

// MARK: SargonUniFFI.NfcTagDriver
extension NFCSessionClient: SargonUniFFI.NfcTagDriver {
	public func startSession(purpose: NfcTagDriverPurpose) async throws {
		self.signingRequestWasTriggered = false
		self.purpose = purpose
		try await self.beginSession()
	}

	public func endSession(withFailure: CommonError?) async {
		let errorMessage = switch withFailure {
		case let .ArculusCardWrongPin(numberOfRemainingTries):
			if numberOfRemainingTries == 0 {
				L10n.ArculusScan.CardBlockedError.message
			} else {
				L10n.ArculusDetails.VerifyPin.errorMessage(Int(numberOfRemainingTries))
			}
		case .NfcSessionLostTagConnection:
			L10n.ArculusScan.LostTagError.message
		default: withFailure?.errorMessage
		}

		self.invalidateSession(error: errorMessage)
		await self.setIsoTag(tag: nil)
	}

	public func sendReceive(command: Data) async throws -> Data {
		try await refreshSessionIfNeed()
		do {
			return try await self.isoTag!.sendCommand(data: command)
		} catch {
			await endSession(withFailure: CommonError.NfcSessionLostTagConnection)
			throw CommonError.NfcSessionLostTagConnection
		}
	}

	public func sendReceiveCommandChain(commands: [Data]) async throws -> Data {
		self.setSigningRequestWasTriggered(true)
		try await refreshSessionIfNeed()
		loggerGlobal.info("======== Sending Command Chain ========")
		do {
			for (index, apdu) in commands.enumerated() {
				let data = try await self.isoTag!.sendCommand(data: apdu)

				if index == commands.count - 1 {
					return data
				}
			}
		} catch {
			loggerGlobal.error("======== Error from NFC Command: \(error) ========")
			await endSession(withFailure: CommonError.NfcSessionLostTagConnection)
			throw CommonError.NfcSessionLostTagConnection
		}
		fatalError()
	}

	public func setProgress(progress: UInt8) async {
		loggerGlobal.info("# NFC progress \(progress)")
		setMessageFor(purpose: self.purpose!, progress: progress)
	}
}

extension NFCSessionClient {
	@discardableResult
	private func refreshSessionIfNeed() async throws {
		func delegateRefreshToSargonIfNeeded() throws {
			guard signingRequestWasTriggered else {
				return
			}
			self.setSigningRequestWasTriggered(false)
			switch purpose {
			case .arculus(.signTransaction), .arculus(.signPreAuth), .arculus(.proveOwnership):
				// If the session is refreshed during the process of signing multiple payloads
				// it is needed to delegate back to Sargon so that in can handle it accordingly.
				// More specifically it is needed to re-verify the pin before sending the signing request.
				// This fix is non-robust quick fix due to time limits. There should be a better mechanism
				// allowing Sargon to tell if a given request needs to have special handling when a session is refreshed.
				throw CommonError.NfcSessionRenewed
			default:
				break
			}
		}

		if self.sessionStartTime.distance(to: .now) >= 30 {
			loggerGlobal.info("========= Restarting NFC session \(Date.now) ========== ")
			try await self.restartSession()
			try delegateRefreshToSargonIfNeeded()
		} else if self.sessionRenewTime.distance(to: .now) >= 10 {
			loggerGlobal.info("========= Renewing NFC session ========== ")
			try await self.renewSession()
			try delegateRefreshToSargonIfNeeded()
		}
	}

	private func setMessageFor(purpose: NfcTagDriverPurpose, progress: UInt8?) {
		let progress = if let progress {
			"Progress: \(progress)%"
		} else {
			""
		}

		let nfcInstruction = "Tap and hold your Arculus Card to your phone. Don't remove your card until the operation is complete 100% or an error is shown."

		switch purpose {
		case let .arculus(arcPurpose):
			switch arcPurpose {
			case .identifyingCard:
				session?.alertMessage = """

				Identifying Card

				\(progress)

				\(nfcInstruction)

				"""
			case .configuringCardMnemonic:
				session?.alertMessage = """
				Configuring your arculus Card

				\(progress)

				\(nfcInstruction)

				"""
			case .signTransaction:
				session?.alertMessage = """
				Signing Transaction

				\(progress)

				\(nfcInstruction)

				"""
			case .signPreAuth:
				session?.alertMessage = """
				Signing Pre-Authorization

				\(progress)

				\(nfcInstruction)

				"""
			case .proveOwnership:
				session?.alertMessage = """
				Proving Onwership

				\(progress)

				\(nfcInstruction)

				"""
			case .derivingPublicKeys:
				session?.alertMessage = """
				Deriving Public Keys

				\(progress)

				\(nfcInstruction)

				"""
			case .verifyingPin:
				session?.alertMessage = """
				Verifying Card PIN

				\(progress)

				\(nfcInstruction)

				"""
			case .configuringCardPin:
				session?.alertMessage = """
				Configuring new Card PIN

				\(progress)

				\(nfcInstruction)

				"""
			case .restoringCardPin:
				session?.alertMessage = """
				Restoring Card Pin

				\(progress)

				\(nfcInstruction)

				"""
			}
		}
	}

	private func beginSession() async throws {
		let delegate = NFCTagReaderSessionAsyncDelegate()
		let session = NFCTagReaderSession(pollingOption: .iso14443, delegate: delegate, queue: .main)!

		self.session = session
		self.delegate = delegate

		setMessageFor(purpose: self.purpose!, progress: nil)

		session.begin()
		loggerGlobal.info("======== Session begin called \(Date.now)========")
		await self.setSesssionStartTime(date: .now)
		await self.setSesssionRenewTime(date: .now)
		loggerGlobal.info("======== Session begin connecting tag ========")
		let tag = try await connectTag()
		await self.setIsoTag(tag: tag)
	}

	private func renewSession() async throws {
		self.session?.restartPolling()
		let tag = try await connectTag()
		await self.setIsoTag(tag: tag)
		await self.setSesssionRenewTime(date: .now)
	}

	private func restartSession() async throws {
		self.invalidateSession(true)
		try await ContinuousClock().sleep(for: .seconds(4))
		try await self.beginSession()
	}

	private func connectTag() async throws -> NFCISO7816Tag {
		for try await tags in self.delegate!.onSessionTagDetected.prefix(1) {
			let tag = tags.first { tag in
				if case .iso7816 = tag {
					true
				} else {
					false
				}
			}

			guard let cardTag = tag, case let .iso7816(isoTag) = tag else {
				self.invalidateSession(error: "Unknown Arculus Card")
				throw CommonError.NfcSessionUnknownTag
			}

			guard Self.supportedAIDs.contains(isoTag.initialSelectedAID) else {
				struct UnknownCardError: Error {}
				self.invalidateSession(error: "Unknown Arculus Card")
				throw CommonError.NfcSessionUnknownTag
			}

			do {
				try await self.session?.connect(to: cardTag)
				AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
			} catch {
				self.invalidateSession(error: "Failed to connect Card, please retry")
				throw CommonError.NfcSessionLostTagConnection
			}
			return isoTag
		}
		throw CancellationError()
	}

	private func invalidateSession(_ isComplete: Bool = false, error: String? = nil) {
		if let err = error {
			session?.invalidate(errorMessage: err)
		} else {
			session?.invalidate()
		}
		session = nil
		delegate = nil
		isoTag = nil
	}
}

extension NFCISO7816Tag {
	public func sendCommand(data: Data, file: StaticString = #filePath, fun: StaticString = #function) async throws -> Data {
		guard let command = NFCISO7816APDU(data: data) else {
			throw NFCReaderError(.readerErrorInvalidParameterLength)
		}

		let (response, statusBytesSW1, statusBytesSW2) = try await sendCommand(apdu: command)
		let result = response + Data([statusBytesSW1]) + Data([statusBytesSW2])

		loggerGlobal.info("# NFC request response for \(fun), request: \(data.hex), response: \(result.hex)")
		return result
	}

	func sendCommandChain(_ apdus: [Data]) async throws -> Data {
		for (index, apdu) in apdus.enumerated() {
			let data = try await sendCommand(data: apdu)

			if index == apdus.count - 1 {
				return data
			}
		}

		fatalError()
	}
}

import AsyncExtensions

final class NFCTagReaderSessionAsyncDelegate: NSObject {
	let onSessionDidBecomeActive: AsyncThrowingStream<Void, Error>
	private let onSessionDidBecomeActiveContinuation: AsyncThrowingStream<Void, Error>.Continuation

	let onSessionTagDetected: AsyncThrowingStream<[NFCTag], Error>
	private let onSessionTagDetectedContinuation: AsyncThrowingStream<[NFCTag], Error>.Continuation

	override init() {
		(onSessionTagDetected, onSessionTagDetectedContinuation) = AsyncThrowingStream.makeStream()
		(onSessionDidBecomeActive, onSessionDidBecomeActiveContinuation) = AsyncThrowingStream.makeStream()
	}
}

extension NFCTag: @unchecked @retroactive Sendable {}

extension NFCTagReaderSessionAsyncDelegate: NFCTagReaderSessionDelegate {
	func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
		loggerGlobal.info("======== Session did become active ========")
		onSessionDidBecomeActiveContinuation.yield()
	}

	func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: any Error) {
		let cancellationErrorCodes: [NFCReaderError.Code] = [
			.readerSessionInvalidationErrorSessionTimeout,
			.readerSessionInvalidationErrorSessionTerminatedUnexpectedly,
			.readerSessionInvalidationErrorUserCanceled,
		]

		if let nfcError = error as? NFCReaderError {
			let commonError = if cancellationErrorCodes.contains(nfcError.code) {
				CommonError.HostInteractionAborted
			} else {
				CommonError.NfcSessionLostTagConnection
			}
			loggerGlobal.error("======== Error from NFC delegate: \(error) ========")
			onSessionDidBecomeActiveContinuation.finish(throwing: commonError)
			onSessionTagDetectedContinuation.finish(throwing: commonError)
		}
	}

	func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
		onSessionTagDetectedContinuation.yield(tags)
	}
}
