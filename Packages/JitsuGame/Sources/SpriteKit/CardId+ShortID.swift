//
//  CardId+ShortID.swift
//  JitsuGame
//
//  Created by Tom Knighton on 24/02/2026.
//

import JitsuCore

extension CardId {
    var shortID: String {
        String(describing: rawValue)
    }
}
