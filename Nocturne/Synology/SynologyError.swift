import Foundation

/// 群晖 API 错误统一抽象。
enum SynologyError: LocalizedError, Equatable {
    case missingBaseURL
    case invalidResponse
    case http(Int)
    case decoding(String)
    case api(code: Int, message: String)
    case notAuthenticated
    case network(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .missingBaseURL: return "服务器地址无效"
        case .invalidResponse: return "服务器返回内容不正确"
        case .http(let code): return "HTTP 错误（\(code)）"
        case .decoding(let m): return "解析返回数据失败：\(m)"
        case .api(_, let m): return m
        case .notAuthenticated: return "尚未登录或会话已过期"
        case .network(let m): return "网络错误：\(m)"
        case .cancelled: return "请求已取消"
        }
    }

    /// 群晖通用错误码映射为中文文案。详见 Synology Web API 文档。
    static func describe(authCode code: Int) -> String {
        switch code {
        case 400: return "账号或密码错误"
        case 401: return "账号或密码错误"
        case 402: return "权限不足"
        case 403: return "需要双重验证（请输入 OTP）"
        case 404: return "双重验证码错误"
        case 405: return "账号被锁定"
        case 406: return "需要启用 OTP"
        case 407: return "登录被 IP 限制"
        case 408: return "需要修改密码"
        case 409: return "密码已过期"
        case 410: return "密码过期"
        case 411: return "账号已过期"
        default: return "认证失败（code \(code)）"
        }
    }

    static func describe(commonCode code: Int) -> String {
        switch code {
        case 100: return "未知错误"
        case 101: return "无效参数"
        case 102: return "请求的 API 不存在"
        case 103: return "请求的方法不存在"
        case 104: return "请求的版本不支持"
        case 105: return "无权限"
        case 106: return "会话超时"
        case 107: return "会话被另一处登录中断"
        case 119: return "SID 已失效"
        default: return "服务器错误（code \(code)）"
        }
    }
}
