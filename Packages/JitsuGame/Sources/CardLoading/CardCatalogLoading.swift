//
//  CardCatalogLoading.swift
//  JitsuGame
//
//  Created by Tom Knighton on 16/03/2026.
//

import Foundation
import JitsuCore

public protocol CardCatalogLoading: Sendable {
    func loadCatalog() throws -> CardCatalog
}

public struct BundledCardCatalogLoader: CardCatalogLoading, Sendable {
    private let bundle: Bundle
    private let resourceName: String
    private let resourceExtension: String
    
    public init(
        bundle: Bundle,
        resourceName: String = "base-cards",
        resourceExtension: String = "json"
    ) {
        self.bundle = bundle
        self.resourceName = resourceName
        self.resourceExtension = resourceExtension
    }
    
    public func loadCatalog() throws -> CardCatalog {
        guard let url = bundle.url(forResource: resourceName, withExtension: resourceExtension) else {
            throw CocoaError(.fileNoSuchFile)
        }
        
        let data = try Data(contentsOf: url)
        return try CardCatalogDecoder.decode(from: data)
    }
}
