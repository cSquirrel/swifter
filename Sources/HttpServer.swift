//
//  HttpServer.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Foundation
#endif

public class HttpServer: HttpServerIO {
    
    public typealias RequestFilter = (request:HttpRequest) -> HttpRequest
    public typealias ResponseFilter = (request:HttpRequest, response:HttpResponse) -> HttpRequest
    
    public static let VERSION = "1.2.0"
    
    private let router = HttpRouter()
    
    public override init() {
        self.DELETE = MethodRoute(method: "DELETE", router: router)
        self.UPDATE = MethodRoute(method: "UPDATE", router: router)
        self.HEAD   = MethodRoute(method: "HEAD", router: router)
        self.POST   = MethodRoute(method: "POST", router: router)
        self.GET    = MethodRoute(method: "GET", router: router)
        self.PUT    = MethodRoute(method: "PUT", router: router)
        
        self.delete = MethodRoute(method: "DELETE", router: router)
        self.update = MethodRoute(method: "UPDATE", router: router)
        self.head   = MethodRoute(method: "HEAD", router: router)
        self.post   = MethodRoute(method: "POST", router: router)
        self.get    = MethodRoute(method: "GET", router: router)
        self.put    = MethodRoute(method: "PUT", router: router)
    }
    
    public var DELETE, UPDATE, HEAD, POST, GET, PUT : MethodRoute
    public var delete, update, head, post, get, put : MethodRoute
    
    public subscript(path: String) -> ((HttpRequest) -> HttpResponse)? {
        set {
            router.register(nil, path: path, handler: newValue)
        }
        get { return nil }
    }
    
    public var routes: [String] {
        return router.routes();
    }
    
    public var requestFilters = Array<RequestFilter>()
    public var responseFilters = Array<ResponseFilter>()
    
    public var notFoundHandler: ((HttpRequest) -> HttpResponse)?
    
    public var middleware = Array<(HttpRequest) -> HttpResponse?>()

    override public func dispatch(_ request: HttpRequest) -> ([String:String], (HttpRequest) -> HttpResponse) {
        
        let filteredRequest = filterRequest(request: request)
        
        for layer in middleware {
            if let response = layer(filteredRequest) {
                return ([:], { _ in response })
            }
        }
        if let result = router.route(filteredRequest.method, path: filteredRequest.path) {
            return result
        }
        if let notFoundHandler = self.notFoundHandler {
            return ([:], notFoundHandler)
        }
        return super.dispatch(filteredRequest)
    }
    
    public struct MethodRoute {
        public let method: String
        public let router: HttpRouter
        public subscript(path: String) -> ((HttpRequest) -> HttpResponse)? {
            set {
                router.register(method, path: path, handler: newValue)
            }
            get { return nil }
        }
    }
    
    private func filterRequest(request:HttpRequest) -> HttpRequest {

        var result = request
        for filter in requestFilters {
            result = filter(request: result)
        }
        
        return result
    }
}

