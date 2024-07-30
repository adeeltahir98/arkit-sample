//
//  String+Extension.swift
//  ARDummy
//
//  Created by Adeel Tahir on 26/12/2022.
//

import Foundation

extension String {

    // Python-y formatting:  "blah %i".format(4)
    func format(_ args: CVarArg...) -> String {
        return NSString(format: self, arguments: getVaList(args)) as String
    }
    
}
