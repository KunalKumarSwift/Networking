//
//  SARequestFoundation.swift
//  SampleApp
//
//  Created by Kunal Kumar on 2020-10-07.
//

import Foundation

public protocol SAURLBuilder {
    // End point for the request
    var endPoint: String { get }
    
    // Http Method to be used.
    var httpMethod: SAHttpMethod? { get }
    
    // http method for communication. eg. PUT, POST, DELETE, GET
    var requestType: SARequestType? { get }
    
}

public enum SAHttpMethod: String {
    // Use https for request
    case https
    
    // Use http for the request
    case http
    
}

public enum SARequestType: String {
    // Use GET Method
    case GET
    
    // Use POST Method
    case POST

    // Use PUT Method
    case PUT

    // Use DELETE Method
    case DELETE
    
}

public enum SARequestError: Error {
    // 404 Encountered.
    case encountered404
    
    // Other error encountered.
    case otherError(errorCode: Int)
    
}
