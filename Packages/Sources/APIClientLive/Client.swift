//
//  File.swift
//  
//
//  Created by Adrian Macarenco on 01/06/2023.
//

import Foundation
import APIClient

extension APIClient {
    public static func live(
        baseUrl url: URL
    ) -> Self {
        let fileUploader = FileUploader()
        return Self(
            uploadDbFile: {
                var uploadfileUrl = url
                uploadfileUrl.appendPathComponent("api/studies/5300a9b7-204b-4c6b-8757-fec603507200/files")
                let path = NSSearchPathForDirectoriesInDomains(
                     .documentDirectory, .userDomainMask, true
                 ).first!
                let ecgDbPath = "ECGData.sqlite3"
                let folderUrl = URL(filePath: path)
                let dbFileUrl = folderUrl.appendingPathComponent(ecgDbPath)
                try await fileUploader.uploadFile(at: dbFileUrl, at: uploadfileUrl)
            }
        )
    }
}
