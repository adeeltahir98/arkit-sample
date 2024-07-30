//
//  URL+Extension.swift
//  ARDummy
//
//  Created by Adeel Tahir on 26/12/2022.
//

import Foundation

extension URL {
    
    static func documentsDirectory() -> URL {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
        
    }
}
