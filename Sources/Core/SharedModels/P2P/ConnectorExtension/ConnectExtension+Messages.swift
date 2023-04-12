////
////  File.swift
////
////
////  Created by Alexander Cyon on 2023-04-12.
////
//
// import Foundation
//
// extension P2P {
//    public typealias RTCIncomingConnectorResponse = RTCIncomingMessage<P2P.FromConnectorExtension.LedgerHardwareWallet>
//
// }
//
// extension P2P.RTCIncomingMessage where PeerConnectionContent == P2P.FromConnectorExtension.LedgerHardwareWallet {
//
//    public func unwrapSuccess() throws -> P2P.FromConnectorExtension.LedgerHardwareWallet.Success {
//        try peerMessage.content.response.get()
//    }
//
//    public func getDeviceInfoResponse() throws -> P2P.FromConnectorExtension.LedgerHardwareWallet.Success.GetDeviceInfo {
//
//        let success = try unwrapSuccess()
//        guard let deviceInfo = success.getDeviceInfo else {
//            throw WrongResponseType()
//        }
//        return deviceInfo
//    }
//
//    public func signTransactionResponse() throws -> P2P.FromConnectorExtension.LedgerHardwareWallet.Success.SignTransaction {
//
//        let success = try unwrapSuccess()
//        guard let signTransaction = success.signTransaction else {
//            throw WrongResponseType()
//        }
//        return signTransaction
//    }
//
//    public func derivePublicKeyResponse() throws -> P2P.FromConnectorExtension.LedgerHardwareWallet.Success.DerivePublicKey {
//
//        let success = try unwrapSuccess()
//        guard let derivePublicKey = success.derivePublicKey else {
//            throw WrongResponseType()
//        }
//        return derivePublicKey
//    }
// }
//
// struct WrongResponseType: Swift.Error {
//
// }
//
// extension P2P.FromConnectorExtension.LedgerHardwareWallet.Success {
//    public var getDeviceInfo: GetDeviceInfo? {
//        guard case let .getDeviceInfo(wrapped) = self else {
//            return nil
//        }
//        return wrapped
//    }
//    public var signTransaction: SignTransaction? {
//        guard case let .signTransaction(wrapped) = self else {
//            return nil
//        }
//        return wrapped
//    }
//    public var derivePublicKey: DerivePublicKey? {
//        guard case let .derivePublicKey(wrapped) = self else {
//            return nil
//        }
//        return wrapped
//    }
// }
