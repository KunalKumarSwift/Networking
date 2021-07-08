//
//  SANetworkConstants.swift
//  Loblaw Digital
//
//  Created by Kunal Kumar on 2019-08-28.
//  Copyright © 2019 Kunal Kumar. All rights reserved.
//

import Foundation

public enum SANetworkConstant {
    static let baseURL: String = "api.nasa.gov"
    static let timeout: Double = 30.0
    static let successfulResponseLowerRange = 200
    static let successfulResponseUpperRange = 202
    static let resourceNotFound = 404
    static let apiKey = "ILCYuOly9PAKokST2fXdWygosq1H40fCdrhutEJi"
    static let apiParameterKey = "api_key"
}
