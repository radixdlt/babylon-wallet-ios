enum RTCPrimitive: Sendable {
        case offer(Offer)
        case answer(Answer)
        case addICE(ICECandidate)
}

extension RTCPrimitive {
        struct Offer: Sendable, Codable, Equatable {
                let sdp: SDP
                init(sdp: SDP) {
                        self.sdp = sdp
                }
        }

        struct Answer: Sendable, Codable, Equatable {
                let sdp: SDP
                init(sdp: SDP) {
                        self.sdp = sdp
                }
        }

        public struct ICECandidate: Sendable, Codable, Equatable {
                public let candidate: SDP
                public var sdp: SDP { candidate }
                public let sdpMLineIndex: Int32
                public let sdpMid: String?

                public init(sdp: SDP, sdpMLineIndex: Int32, sdpMid: String?, serverUrl: String?) {
                        self.candidate = sdp
                        self.sdpMLineIndex = sdpMLineIndex
                        self.sdpMid = sdpMid
                }
        }
}

extension RTCPrimitive {
        var offer: Offer? {
                guard case let .offer(offer) = self else {
                        return nil
                }
                return offer
        }

        var answer: Answer? {
                guard case let .answer(answer) = self else {
                        return nil
                }
                return answer
        }

        var addICE: ICECandidate? {
                guard case let .addICE(ice) = self else {
                        return nil
                }
                return ice
        }
}

extension RTCPrimitive: Encodable {
        func encode(to encoder: Encoder) throws {
                var singleValueContainer = encoder.singleValueContainer()
                switch self {
                case let .offer(value):
                        try singleValueContainer.encode(value)
                case let .answer(value):
                        try singleValueContainer.encode(value)
                case let .addICE(value):
                        try singleValueContainer.encode(value)
                }
        }
}
