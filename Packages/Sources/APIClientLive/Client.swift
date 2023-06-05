//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 01/06/2023.
//

import Foundation
import APIClient
import Model

extension APIClient {
    public static func live(
        baseUrl url: URL,
        authenticationHandler: AuthenticationHandlerAsync
    ) -> Self {
        return Self(
            uploadDbFile: {
                var uploadfileUrl = url
                uploadfileUrl.appendPathComponent("api/studies/d5f7ab8c-9f27-4b50-9cf5-eb3a19ca993e/files")
                let path = NSSearchPathForDirectoriesInDomains(
                     .documentDirectory, .userDomainMask, true
                 ).first!
                let ecgDbPath = "ECGData.sqlite3"
                let folderUrl = URL(filePath: path)
                let dbFileUrl = folderUrl.appendingPathComponent(ecgDbPath)
                let result = try await authenticationHandler.performAuthenticatedUploadRequest(makePostRequest(url: uploadfileUrl), dbFileUrl)
            }
        )
    }
}
