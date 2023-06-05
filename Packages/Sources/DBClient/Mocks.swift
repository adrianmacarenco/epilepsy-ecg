//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 06/06/2023.
//

import Foundation

extension DBClient {
    public static let mock = Self(
    dbPathUrl: "",
    createUser: { _,_,_,_,_,_,_ in return .mock },
    getUser: { _ in return .mock },
    updateUser: { _ in },
    createMedication: { _, _ in return .mock },
    fetchMedications: { return [] },
    updateMedication: { _ in },
    updateMedications: { _ in },
    deleteMedication: { _ in },
    addIntake: { _, _, _ in return .mock },
    updateIntake: { _ in },
    fetchDailyIntakes: { return [] },
    fetchIntakes: { return [] },
    addEcg: { _ in },
    fetchRecentEcgData: { _ in return [] },
    clearDb: {},
    deleteCurrentDb: { }
    )
}
