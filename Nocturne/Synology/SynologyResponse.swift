import Foundation

/// 群晖 Web API 标准响应外层。
struct SynologyResponse<Payload: Decodable>: Decodable {
    let success: Bool
    let data: Payload?
    let error: SynologyAPIError?
}

/// 群晖 API 错误信息。
struct SynologyAPIError: Decodable {
    let code: Int
    /// errors 是可选数组，包含额外提示。
    let errors: [SynologyAPIErrorDetail]?
}

struct SynologyAPIErrorDetail: Decodable {
    let code: Int?
}

/// 空 payload 占位。
struct EmptyPayload: Decodable {}
