//
//  OfferSignature.swift
//

public struct OfferSignature: Codable {
    let keyID: String
    let nonce: String
    let timestamp: Int
    let signature: String
}

